# WpfGfx.Linux 架构文档

> **本文只描述已经落地的代码**。每条论断都带 `路径:行号` 或实测数字；没做的写"没做"，不写"计划中"。
> 数据基准：2026-09-03，`Xvfb :99 1280x1024x24`，390 测试通过 / 0 失败，命令层 108/118。
> 上游对照仓库：`/root/.codebuddy/artifact/wpfscan/wpf`（dotnet/wpf main）。

---

## 1. 定位：渲染后端，不是托管层跨平台

一句话：**`WpfGfx.Linux` 是 MIL（Media Integration Layer）的 Linux 重写实现，用来替换 `wpfgfx_cor3.dll`。
它消费 DUCE 命令流，输出像素。它不含、也不模拟 WPF 托管层的任何业务语义。**

| 子系统 | 属于哪一层 | 本工程有没有 |
|---|---|---|
| DUCE 命令（118 条）/ 资源表 / 通道批处理 | 渲染后端 | ✅ 已实现 108/118 |
| RenderData 绘图指令（25 条）/ 画刷 / 几何 / 变换 / 效果 | 渲染后端 | ✅ 已实现 |
| 窗口与呈现（X11）/ 文本（GlyphRun） | 渲染后端 | ✅ 已实现 |
| 布局 `Measure/Arrange` | WPF **托管层** | ❌ 不存在——后端只消费已排好版的视觉树 |
| `DependencyProperty` / 数据绑定 / 动画时间线 | WPF **托管层** | ❌ 不存在 |
| XAML / BAML 运行时加载 | WPF **托管层** | ❌ 不存在（T1 只打通了**编译期** BAML 产出） |

给不存在的子系统写测试是无意义的，因此 handoff §8 已把「布局/属性/绑定」从欠账中划掉。

**层间唯一契约**是字节流：托管层把命令写成字节，我们解码成字节。只要字节布局对得上，托管层一行都不用改
（handoff §2 决策 1、决策 3：接入点收敛到 `Common/Graphics/exports.cs` 一个文件，M2 才动它）。

---

## 2. 全局架构

```
 ┌──────────────────────────────────────────────────────────────────────────┐
 │  WPF 托管层（PresentationFramework / PresentationCore / WindowsBase）      │
 │  ⚠️ 未移植，不属本工程。M2 才通过 exports.cs 的 13 个函数接进来            │
 └────────────────────────────────┬─────────────────────────────────────────┘
                                  │  DUCE 命令流（字节）
                                  │  BeginCommand → Append* → EndCommand → CommitChannel
                                  ▼
 ┌──────────────────────────────────────────────────────────────────────────┐
 │ L1  Interop/            825 行   13 个 MIL 导出函数 + 全局通道注册表        │
 │     MilNative.cs:34-213    签名逐字对齐上游 exports.cs:113-204             │
 └────────────────────────────────┬─────────────────────────────────────────┘
                                  │  ReadOnlySpan<byte> 单条命令
                                  ▼
 ┌──────────────────────────────────────────────────────────────────────────┐
 │ L2  Commands/          4,869 行   解码：字节 → 资源字段 / 绘图指令序列      │
 │     MilCommandDispatcher.cs:30   MilCommandLayout.cs:20  长度表            │
 │     MilCommandStructs.cs        101 个线格结构体（与上游逐 FieldOffset 一致）│
 └────────────────────────────────┬─────────────────────────────────────────┘
                                  │  写入资源对象
                                  ▼
 ┌──────────────────────────────────────────────────────────────────────────┐
 │ L3  Resources/         1,366 行   句柄表 + 视觉树节点 + 句柄图投影          │
 │     MilResourceTable.cs:44 引用计数   MilVisualNode.cs:24 节点             │
 │     VisualProjection.cs:25 句柄图 → 契约 MilVisual（渲染层消费的模型）     │
 └────────────────────────────────┬─────────────────────────────────────────┘
                                  │  Contracts.MilVisual 树
                                  ▼
 ┌──────────────────────────────────────────────────────────────────────────┐
 │ L4  Rendering/         1,509 行   Skia CPU 后端：遍历树 + 执行 25 条指令    │
 │     SkiaRenderBackend.cs:66 入口   SkiaBrush/Pen/Geometry/Color            │
 └───────────┬──────────────────────────────────────┬───────────────────────┘
             │ SKCanvas（离屏 SKSurface 或窗口位图） │ 字形扩展点
             ▼                                      ▼
 ┌────────────────────────┐          ┌──────────────────────────────────────┐
 │ L5  Text/       705 行 │          │ L6  Windowing/         1,096 行       │
 │  FontSet（封闭字体集） │          │  X11Window.Present:168               │
 │  GlyphRunLayout:46     │          │  帧 → visual 掩码打包 → XPutImage     │
 └────────────────────────┘          └──────────────────────────────────────┘
             │                                      │
             └──────────────┬───────────────────────┘
                            ▼
                   SKImage → X11 窗口（XID）→ xwd 独立进程截屏验证
```

`Contracts/`（631 行）是**只读契约层**，被 L1–L6 共同引用，不依赖任何一层。

| 目录 | 文件数 | 行数 | 职责一句话 |
|---|---:|---:|---|
| `src/WpfGfx.Linux/Contracts/` | 5 | 631 | 三个跨组接口 + 两个枚举 + 两个数据模型 |
| `src/WpfGfx.Linux/Interop/` | 7 | 825 | 13 个 MIL 导出函数、HRESULT、DUCE 句柄 |
| `src/WpfGfx.Linux/Commands/` | 7 | 4,869 | 118 条顶层命令解码 + 25 条绘图指令切分 |
| `src/WpfGfx.Linux/Resources/` | 5 | 1,366 | 句柄表、引用计数、视觉树节点、投影 |
| `src/WpfGfx.Linux/Rendering/` | 9 | 1,509 | Skia 后端：树遍历、画刷、画笔、几何、颜色 |
| `src/WpfGfx.Linux/Windowing/` | 6 | 1,096 | X11 连接 / 窗口 / 事件 / 呈现目标 |
| `src/WpfGfx.Linux/Text/` | 8 | 705 | 字体集、GlyphRun 排版与绘制 |

---

## 3. 分层说明

### 3.0 Contracts —— 只读契约层

| 类型 | 位置 | 由谁实现 / 消费 |
|---|---|---|
| `IMilCommandDispatcher` | `Contracts/Interfaces.cs:9` | Commands 实现，MilChannel 调用 |
| `IMilChannel` | `Interfaces.cs:22` | Resources 实现（批处理状态机 + 资源表） |
| `IMilResourceTable` | `Interfaces.cs:40` | Resources 实现 |
| `MilVisual` | `Interfaces.cs:52` | **渲染层消费的视觉树节点**（`SKMatrix`/`SKRect`/子节点对象，不再是句柄） |
| `IMilRenderData` / `MilDrawInstruction` | `Interfaces.cs:81` / `:90` | Commands 产出，Rendering 执行 |
| `IRenderBackend` | `Interfaces.cs:124` | Rendering 实现 |
| `IPresentationTarget` | `Interfaces.cs:134` | Windowing 实现（X11），测试实现（离屏） |
| `RenderContext` | `Interfaces.cs:148` | 渲染环境参数；`FixedDpi = 96f` 在 `Interfaces.cs:151` |

**`RenderContext` 是 `sealed`**（`Interfaces.cs:148`）。这一条约束直接决定了 L4 的设计：画刷/几何在指令流里全是**句柄**，
而句柄解析需要资源表，但 `sealed` 的 `RenderContext` 装不进去。解法是把资源解析做成后端**构造期注入**
（`Rendering/MilResourceProvider.cs:38-66`），而不是往上下文里塞字段。

### 3.1 Interop —— 对外协议面

**职责**：实现上游 `Common/Graphics/exports.cs` 的 13 个导出函数（签名逐字对齐 `exports.cs:113-204`），
把 `IntPtr` 通道句柄翻译成 `MilChannel` 实例。

| 函数 | 位置 | 语义要点 |
|---|---|---|
| `MilConnection_CreateChannel` | `Interop/MilNative.cs:34` | `hChannel != 0` 时共享参考通道的分区 |
| `MilConnection_DestroyChannel` | `:57` | 清资源表 + 注销句柄 |
| `MilConnection_CloseBatch` | `:68` | 本实现批次边界无副作用，仅校验无未闭合命令 |
| `MilConnection_CommitChannel` | `:75` | → `MilChannel.Commit()`，**命令的真正执行点** |
| `WgxConnection_SameThreadPresent` | `:82` | 遍历**全局静态**注册表，按 `Connection` 批量提交 |
| `MilChannel_GetMarshalType` | `:94` | 恒为 `SameThread` |
| `MilResource_CreateOrAddRefOnChannel` | `:109` | 句柄为 Null → 新建（RefCount=1）；否则 AddRef |
| `MilResource_ReleaseOnChannel` | `:120` | RefCount--，归零摘除并回填 `deleted` |
| `MilResource_DuplicateHandle` | `:135` | 跨分区拒绝 `E_INVALIDARG`（上游语义：句柄只在分区内有效） |
| `MilResource_SendCommand` | `:156` | 整条命令一次写入；`sendInSeparateBatch=true` 立即执行 |
| `MilChannel_BeginCommand` | `:168` | 先写头部，预留 `cbExtra` 字节变长载荷 |
| `MilChannel_AppendCommandData` | `:180` | 累计不得超过 `cbExtra` |
| `MilChannel_EndCommand` | `:190` | 记账一条完整命令长度 |
| `SendCommandMedia` / `SendCommandBitmapSource` / `SetNotificationWindow` | `:201` / `:206` / `:211` | 恒 `E_NOTIMPL`（见 §5） |

**通道句柄是 `GCHandle`，不是内核对象**（`MilNative.cs:13-14`、`Resources/MilChannel.cs:328-335`）。
后果：不能跨进程、不能 `CloseHandle`；`WgxConnection_SameThreadPresent`（`MilNative.cs:82-92`）必须遍历
`MilChannelRegistry` 这张**进程级静态表**。这是 §8 里 flaky 的根因面。

### 3.2 Commands —— 字节 → 状态

**输入**：一条完整命令的字节（头部 `MILCMD` 4 字节 + 句柄 4 字节 + 载荷）。
**输出**：把字段落到资源对象上，返回 HRESULT。

三条硬规则写在 `Commands/MilCommandDispatcher.cs:8-11`：

1. 长度不足固定部分 → `E_INVALIDARG`（宁可报错，不读越界字节）
2. 句柄不在表里 → `E_HANDLE`
3. 资源类型与命令不符 → `E_INVALIDARG`

| 组件 | 位置 | 说明 |
|---|---|---|
| `MilCommandLayout.FixedSize` | `Commands/MilCommandLayout.cs:20` | 118 条命令的固定长度表；未知返回 `-1` |
| `HasVariablePayload` | `:168` | 15 条命令带尾部变长数组 |
| `s_notImpl` | `:202` | 9 条 `E_NOTIMPL` 登记表（C 类 6 + B 类 3） |
| `MilCommandDecoder` | `Commands/MilCommandDecoder.cs:25` | 小端读取；`ReadFixed<T>` 用 `MemoryMarshal.Read` 打线格结构体 |
| `RenderDataStream` | `:152` | RenderData 内层记录框 `[Size:int32][Id:int32][payload]`，`Size` 含头自身 |
| 线格结构体 | `Commands/MilCommandStructs.cs`（1,190 行） | **101 个**与上游 `Generated/wgx_commands.cs` 逐 `FieldOffset` 一致 |

**3D 的落地手法值得单独说**：`Resources/MilResourceTable.cs:244-247` 的工厂对 3D 类型一律返回占位
`MilOpaqueResource`，而 `Resources/` 不在 Commands 组的可改范围内。于是 29 条 3D 命令（0x57–0x6b 的 21 条 +
0x29–0x30 的 8 条）的解码结果挂在**以资源实例为弱键的 `ConditionalWeakTable` 附加表**上
（`Commands/MilResource3D.cs:346-348`）：不改 `Resources/` 一行、资源释放后表项自动回收、句柄复用不会读到上一任残留。

**边界（不掩饰）**：这 29 条做到「字段 100% 解码 + 状态落地」，**不做 3D 光栅化**——M1 没有 3D 场景图，
解码结果目前没有消费者（`docs/unimplemented.md:103-104`）。

### 3.3 Resources —— 句柄表与视觉树

| 类型 | 位置 | 说明 |
|---|---|---|
| `MilPartition` | `Resources/MilChannel.cs:23` | 分区；同分区内通道可 `DuplicateHandle` |
| `MilChannel` | `:36` | 批处理缓冲（初始 8 KB，翻倍扩容 `:217-228`）+ 状态机 |
| `MilResourceTable` | `Resources/MilResourceTable.cs:27` | `Dictionary<uint, MilResourceEntry>` + 空闲句柄栈；句柄 0 恒为 Null |
| `MilResourceFactory` | `:181` | `ResourceType` → 具体资源类；未建模类型落到 `MilOpaqueResource` |
| `MilVisualNode` | `Resources/MilVisualNode.cs:24` | 视觉树节点，字段与命令字一一对应（文件头 `:5-17` 有对照表） |
| `VisualProjection` | `Resources/VisualProjection.cs:25` | **句柄图 → 契约 `MilVisual`** 的投影 |
| `TransformResolver` | `:82` | 变换句柄 → `SKMatrix`（递归解 `TransformGroup`，深度上限 16） |

**批处理状态机**（`MilChannel.cs:104-196`）：

```
BeginCommand(head, cbExtra) → AppendCommandData*（累计 ≤ cbExtra）→ EndCommand()
        → …（可重复）… → Commit()：按入队顺序逐条 Dispatch，然后清空缓冲
                      ↘ SendCommand(整条, separateBatch=true)：立即执行这一条，回滚缓冲
```

`Commit` 是原子的、按序的（`:184-191`）；每条命令的返回值进 `AccountDispatchResult`（`:198-215`），
落在 `CommittedCommands` / `NotImplCommands` / `NotImplRegistry` / `FailedCommands` / `ShortCommands` 五个计数器上。

**契约与实现的一处摩擦**：`IMilChannel` 的四个写入方法返回 `void`，无法回传 HRESULT。
实现的选择是：正常路径静默，违反状态机（未 Begin 就 Append、未 End 就 Commit）**直接抛异常**并累加
`ContractErrors`（`MilChannel.cs:256-302`）——理由写在 `:258-261`：比悄悄丢命令更容易定位。

**另一处摩擦**：契约用 `MilResourceType/MilResourceHandle`，实现内部用 `DUCE.ResourceType/DUCE.ResourceHandle`
（`Interop/Duce.cs:20` / `:127`）。两者取值与宽度逐项一致，桥接层只做零成本转换（`MilResourceTable.cs:143-177`）。

### 3.4 Rendering —— Skia 后端

**入口**：`SkiaRenderBackend.RenderVisualTree(MilVisual, SKCanvas, RenderContext)`
（`Rendering/SkiaRenderBackend.cs:66`）。

矩阵约定全文统一，写在文件头 `:5-13`（**改一处必须读全文**）：

| 场景 | 公式 | 位置 |
|---|---|---|
| 子视觉世界矩阵 | `world = parent · Transform · Translate(Offset)` | `:96-98` |
| 画布最终矩阵 | `CTM = world · deviceBase` | `:118` |
| `MilPushTransform` | `CTM' = m · CTM`（**先局部、后已有**） | `:347-354` |

最后一条最反直觉：直接 `canvas.Concat(m)` 得到的是 `CTM·m`，与 WPF 语义相反，所以一律用
`SetMatrix(Concat(m, TotalMatrix))`。

Push/Pop 平衡策略（`:15-17`、`:106`、`:130`、`:143`、`:154`、`:380`）：每条 `MilPush*` 恰好压**一层**，
`MilPop` 恰好弹一层；每个 Visual 与每段 Content 各自记 `SaveCount` 入口值，出口 `RestoreToCount` 兜底。
这样指令流哪怕不配平也不会污染后续帧——代价是写过两处 bug（一次 Push 压两层），见 `SkiaRenderBackend.cs:330-334` 与 `:366-370` 的现场注释。

| 子模块 | 位置 | 覆盖 / 已知简化 |
|---|---|---|
| 指令执行 | `SkiaRenderBackend.Execute:157` | 25 条；`*Animate` 变体从原始字节回读静态字段（`:19-23`） |
| 画刷 | `Rendering/SkiaBrush.cs:33` | Solid / LinearGradient / RadialGradient；TileBrush（Image/Drawing/Visual）返回 `null` |
| 画笔 | `Rendering/SkiaPen.cs:26` | DashCap 未实现；`Triangle` 线帽退化成 Butt（`:8-11`） |
| 几何 | `Rendering/SkiaGeometry.cs:30` | Line / Rectangle / Ellipse / Path / Group / Combined |
| PathGeometry | `Rendering/PathGeometryParser.cs:45` | 段类型长度表抄自 `wgx_core_types.cs:1010+`；**Arc 未与 WPF 真机比对过**（`:171-179` 诚实标注） |
| 颜色 | `Rendering/SkiaColor.cs:25` | `MilColorF` 是 **scRGB**，逐行抄上游 `Color.ScRgbTosRgb`，含 `+0.5` 取整偏置 |
| 效果 | `SkiaRenderBackend.cs:538` | Blur / DropShadow；σ = Radius/3（抄上游 `BlurEffect.cpp:351`） |
| 诊断 | `Rendering/RenderDiagnostics.cs:14` | 每帧清零的 `InstructionCount` / `NotDrawn` / `Degraded` |

**两个扩展点**（`Rendering/MilResourceProvider.cs:44`、`:50`）：`BitmapResolver` 与 `GlyphRunRenderer`
默认都是 `null`，未注册时 `MilDrawImage` / `MilDrawGlyphRun` 被记进 `NotDrawn` 而不是静默吞掉。
Text 层通过 `TextRenderer.AttachTo`（`Text/TextRenderer.cs:99`）挂上去，**不修改 `Rendering/` 一行**。

### 3.5 Text —— GlyphRun

**输入**：`MilGlyphRun` 资源（`Resources/MilResources.cs:405`）+ 前景 `SKPaint`。
**输出**：在画布上画出字形；返回 `false` 表示没画（会被记进 `NotDrawn`）。

| 组件 | 位置 | 关键事实 |
|---|---|---|
| `FontSet` | `Text/FontSet.cs:52` | **封闭目录**：只认传入目录，查不到返回 `false`，**绝不回落系统字体**（`:100-101`） |
| 索引方式 | `:83-87` | 用字体自己 name 表的 `FamilyName/FontWeight/FontSlant`，不靠文件名；文件名只用于排序（`:58-64`） |
| 查找策略 | `:102-117` | 先精确（家族+字重+倾斜），再近似（家族+粗/斜三元组） |
| `GlyphRunLayout.Measure` | `Text/GlyphRunLayout.cs:46` | `pos[i] = baselineOrigin + Σ advance[0..i-1] + offset[i]`（`:94`） |
| 步进优先级 | `:112-141` | ① 显式 `AdvanceWidths` → ② 字体度量 → ③ 0 |
| 越界字形 | `:71-79` | 超出 `Typeface.GlyphCount` 的 id 兜底成 `.notdef(0)` 并计数 |
| `GlyphRunPainter.Draw` | `Text/GlyphRunPainter.cs:22` | 逐字形 `DrawText` |
| `SKFont` 缓存 | `Text/TextRenderer.cs:29`、`:126-131` | 按 `(typeface.Handle, size)` 缓存，避免每帧 new native 对象 |

**一个必须说清楚的坑**：上游 `MILCMD_GLYPHRUN_CREATE` 里只有一个 `ulong PIDWriteFont`——
指向 Windows DirectWrite 字体对象的**裸指针**，在 Linux 上解引用就是段错误。而字形 id 是**字体相关**的。
M1 的对接契约写在 `Text/MilGlyphRunAdapter.cs:3-15`：渲染器构造期绑定默认字体（打包的 Noto Sans），
并提供 `TextRenderer.MilFontResolver`（`TextRenderer.cs:52`）钩子供将来托管层按自己的 `Typeface` 映射翻译。
**这不是"以后再说"，是 M1 阶段唯一可行的做法**——FontFamily 解析在托管层，不在 MIL 协议里。

### 3.6 Windowing —— X11 呈现

| 类型 | 位置 | 说明 |
|---|---|---|
| `X11Display` | `Windowing/X11Display.cs:44` | 一条 X 连接，`IDisposable`；`null` 参数即读 `$DISPLAY` |
| `X11Window` | `Windowing/X11Window.cs:58` | 顶层窗口：创建 → 读 visual 掩码 → 选事件 → 注册 `WM_DELETE_WINDOW` |
| `X11Window.Present` | `:168` | 帧 → 与窗口尺寸取交集 → `ReadFrame` → `BlitToWindow` → `XFlush` |
| `X11PresentationTarget` | `Windowing/X11PresentationTarget.cs:25` | `IPresentationTarget` 的 X11 实现；`NativeHandle = (nint)XID`（`:44`） |
| `WindowEvent` / `X11EventType` | `Windowing/WindowEvent.cs` | X11 `XEvent`（192 字节 union）→ 最小事件抽象 |

**呈现为什么走 CPU 位图 + `XPutImage`**（`X11Window.cs:3-7`）：Skia GPU 后端需要 EGL/GLX 上下文，
在 Xvfb 里要额外装 Mesa 且容易踩驱动坑；`XPutImage` 依赖最少、行为最可预测，代价是每帧一次内存拷贝 + 一次 X 请求。

**像素打包必须读 visual 的 RGB 掩码**（`:9-14`、`:84-90`）：24 位深度常见 `0x00RRGGBB`，但 16 位是 5-6-5，
其他服务器也可能是 BGR。写死会让"换个深度就整体偏色"，而偏色只在截屏比对时才暴露。所以从
`XGetWindowAttributes` 拿 visual 读 `red/green/blue_mask`（`:360-365`）。索引色 visual（掩码为 0）直接抛
`NotSupportedException`（`:92-98`），不画一屏乱码。

**半透明要手工合成**（`:384-398`）：`XPutImage` 是覆盖式写入，暂存位图是 RGBA8888 **预乘**，
必须先还原直通通道再与窗口背景做 source-over，否则透明区变黑。

**事件转换**（`:240-320`）：`Expose→Exposed`、`ConfigureNotify→Resized`（以 server 报的尺寸为准，`:254-257`）、
`KeyPress/Release→Key*`、`Button*/MotionNotify→Mouse*/PointerMoved`、`ClientMessage(WM_DELETE_WINDOW)→Closed`。
键鼠的**转换代码**写了但**没有测试覆盖**（`WindowEvent.cs:11-15` 如实标注）。

---

## 4. 关键数据流：一条 `MilDrawRectangle` 从字节到屏幕像素

以 `samples/HelloMil` 里的红矩形（`SKRect(100,100,400,300)`，填充 `(200,30,30)`）为例。

| # | 阶段 | 位置 | 发生了什么 |
|---|---|---|---|
| 1 | 命令入队 | `Interop/MilNative.cs:156` 或 `:168-190` | 托管层（此处是测试/样例直接调用）把字节交给 `MilChannel.SendCommand` / `BeginCommand+EndCommand` |
| 2 | 缓冲 | `Resources/MilChannel.cs:217` | `Append` 把字节拷进 `_batch`，`_commandLengths` 记一条长度。**此时不执行** |
| 3 | 提交 | `Resources/MilChannel.cs:178` `Commit()` | 按 `_commandLengths` 切段，逐条 `Dispatcher.Dispatch(cmd, this)`（`:184-191`） |
| 4 | 长度校验 | `Commands/MilCommandDispatcher.cs:42-44` | `FixedSize(MilCmdRenderData) = 12`（`MilCommandLayout.cs:51`）；不足 → `E_INVALIDARG` |
| 5 | RenderData 外层 | `MilCommandDispatcher.cs:444-455` | 读 `CbData`，`r.Data = c.Slice(12, cb)`（`:451`），立刻调 `RenderDataDecoder.Decode`（`:453`） |
| 6 | 切记录框 | `MilCommandDecoder.cs:163` `RenderDataStream.Enumerate` | `[Size:int32][Id:int32][payload:Size-8]`；`Size%4!=0` 或越界 → `FormatException` |
| 7 | 填强类型指令 | `Commands/MilRenderData.cs:89-97` | `rectangle@0(32) → Rect`；`hBrush@32`；`hPen@36`。**本层到此为止，不绘图** |
| 8 | 建树 | `MilCommandDispatcher.cs:314` `MilCmdTargetSetRoot` | → `MilChannel.SetRootFromHandle`（`MilChannel.cs:316`）→ `VisualProjection.Project`（`VisualProjection.cs:25`） |
| 9 | 句柄解析 | `VisualProjection.cs:38`、`:42`、`:71` | `Transform`→`SKMatrix`、`Clip`→`SKRect?`、`Content`→`IMilRenderData`（`??=` 兜底再解码一次，`:77`） |
| 10 | 树遍历 | `Rendering/SkiaRenderBackend.cs:90` `RenderVisual` | `world = parent·Transform·Translate(Offset)`（`:96`）；`opacity ≤ 0` 整棵子树跳过（`:102`）；`Save` / `SaveLayer`（`:106-116`）；`SetMatrix(world·deviceBase)`（`:118`）；裁剪（`:120`） |
| 11 | 执行指令 | `SkiaRenderBackend.cs:180-192` | 取 `Rect`/`Brush`（Animate 变体则 `H(raw,32)` 从原始字节读）；`path.AddRect(rect)` → `FillAndStroke` |
| 12 | 画刷解析 | `Rendering/SkiaBrush.cs:33` `CreateFill` | `MilSolidColorBrush` → `SkiaColor.FromMilColorF`（`SkiaColor.cs:46`，**scRGB→sRGB 伽马转换**）→ `WithOpacity` |
| 13 | 落像素 | `SkiaRenderBackend.cs:404` | `canvas.DrawPath(path, fill)` |
| 14 | 出栈 | `SkiaRenderBackend.cs:130` / `:154` | `RestoreToCount(entry)`，与入口 `SaveCount` 对齐 |
| 15 | 上屏 | `Windowing/X11Window.cs:168` `Present` | `ReadFrame`（`:344`，`SKImage`→RGBA8888 预乘位图）→ `BlitToWindow`（`:355`，预乘还原 + 与背景合成 + 按 visual 掩码打包）→ `XPutImage`（`:422`）→ `XFlush`（`:181`） |
| 16 | 验证 | `tests/.../HelloMil.Tests` | 独立进程 `xwd -id <XID>` 走**另一条 X 连接**截屏，断言红色像素数 |

**第 16 步是关键设计**：自己 `XGetImage` 读回来只验证了"我们写的 buffer 能原样读回"，`Present` 那一半没被测到；
`xwd` 看得到内容，才证明窗口真被映射、真被绘制、像素真落到 server 端。

### 一个非显然的旁路通道

契约 `MilDrawInstruction`（`Interfaces.cs:90`）装不下 `*Animate` 变体、Guideline 系列、`PushEffect`、
`PushOpacityMask`。解码器对它们**只填 `Command`**，原始字节原样留在 `MilRenderData.RawPayloads`
（`MilRenderData.cs:19-23`、`:41`）里，由**渲染层**按下标回读（`SkiaRenderBackend.cs:148`、`:587-603`）。
即：命令层与渲染层之间除强类型结构外，还存在一条"原始字节旁路"。

---

## 5. 与上游 dotnet/wpf 的有意差异

| 上游 | 我们 | 理由 | 证据 |
|---|---|---|---|
| C++ MIL 引擎（309,467 行，MSVC 方言 + COM + SEH） | **C# + SkiaSharp 重写**（11,001 行） | 24 万行 MSVC C++ 在 GCC 上是持续噩梦；Skia 本身就是 C++ 高性能实现，C# 只在绑定层 | handoff §2 决策 2 |
| D3D 硬件加速 | **放弃，只做 Skia CPU 软件渲染** | M1 先跑通主链路 | 决策 4；`MilCommandLayout.cs:204-208` |
| `MilCmdPixelShader` / `MilCmdShaderEffect`（HLSL 字节码） | `E_NOTIMPL` | 需 D3D 编译执行环境。**将来要走 Shader → Skia `SKRuntimeEffect`，不是移植 D3D** | `docs/unimplemented.md:118-135` |
| `MilCmdD3DImage` / `D3DImagePresent` | `E_NOTIMPL` | 载荷是 `IDirect3DSurface9` COM 指针 / Windows 事件句柄 | `unimplemented.md:122-123` |
| `MilCmdDoubleBufferedBitmap` / `CopyForward` | `E_NOTIMPL`（**改判为永久不做**） | 卡点不是"子系统没建"，而是 `UInt64` 里装的是 Windows 对象身份，Linux 解释不出语义 | `unimplemented.md:129-133` |
| `IWICBitmapSource` | **无等价物**；`SKBitmap/SKImage` 待定 | 会改变 `MilResource_SendCommandBitmapSource` 的签名语义，属契约变更，须主控协商 | `unimplemented.md:110`、`:171-173` |
| HWND | **X11 Window（XID）** | Linux 上没有 HWND 消息循环 | `X11PresentationTarget.cs:40-44` |
| `HwndTarget` / `MilChannel_SetNotificationWindow` | `E_NOTIMPL`；呈现由渲染层直接驱动 | 同上 | `MilNative.cs:210-212` |
| DirectWrite `PIDWriteFont` | **构造期绑定默认字体 + `MilFontResolver` 钩子** | 裸指针在 Linux 无意义；字形 id 字体相关 | `MilGlyphRunAdapter.cs:3-15` |
| 3D 场景图与光栅化 | **只解码不渲染**（29 条命令字段 100% 落地） | M1 没有 3D 后端 | `unimplemented.md:103-104`、`:201-202` |
| `ColorInterpolationMode`（scRGB 插值空间） | 未实现 | Skia 渐变只在固定色彩空间插值，与 `SRgbLinearInterpolation` 不等价 | `SkiaBrush.cs:12-13` |
| ~~TileBrush（Image/Drawing/VisualBrush）~~ → **✅ 已实现**（**2026-09-11 更正：此行原先写"返回 `null`（不填充）"，已过期**） | Viewbox 选源区 → Stretch/Alignment 映射到 Viewport 基块 → TileMode 平铺 → 画刷变换整链已实现（`SkiaBrush.cs:193-277`）。**FlipX/FlipY 已按真机 oracle 改成 Skia 的轴向对** `(Mirror,Repeat)`=FlipX、`(Repeat,Mirror)`=FlipY、`(Mirror,Mirror)`=FlipXY（**天然覆盖"负索引也按奇偶翻转"**），`TileMode.None → Decal`（"只画基准格、其余为背景"）。**剩余差距**：① **`Viewport` 绝对单位时 WPF 用"被填充图形的局部坐标系"（原点=包围盒左上角），我们现在按画布原点解释**（真机 A/B 假设检验：局部 **194/194** 吻合 vs 画布 **20/216**；瓦片原点实测 `(26,26)`）；② `VisualBrush` 生产接线；③ `ColorInterpolationMode`（下一条） | `SkiaBrush.cs:19-24/193-277`；真值 `tests/parity/brushes/`（批次 1 74 例 + 批次 2 60 例） |
| `DashCap` / `Triangle` 线帽 | 退化成 Butt | Skia 无对应概念 | `SkiaPen.cs:8-11` |
| `PushOpacityMask` 逐像素调制 | **只实现"遮罩是纯色画刷"**（取其 alpha 当整层不透明度） | 真遮罩要"内容画进层 + DstIn 合成"，而 Pop 时机由指令流决定，本层插不进那一笔 | `SkiaRenderBackend.cs:517-521` |
| `Sideways`（竖排） | 只把步进方向换成 +Y，**不做字形旋转** | ~~`vert` 特性需 HarfBuzz~~ → **2026-09-11 真机实测：WPF 上游根本没有竖排文本布局入口**（`System.Windows.Media.TextFormatting` 公开面里含 vertical/writing-mode/upright/rotate/tategaki/orientation 的**只有 `InvertAxes.Vertical`**，而那是 `TextLine.Draw()` 的**坐标轴翻转**参数，与竖排排版无关；`FlowDirection` 只有 LTR/RTL）。⇒ **本项从"我们的缺口"改判为"超出上游能力"**：不是我们没做，是 WPF 没有这东西 ⇒ **`vert` 特性不再是我们必须补的项** | `GlyphRunLayout.cs:16-18`；证据 `tests/parity/windows/layout-b34/probe.json`（`verticalText`） |
| Windows 事件句柄 / `SafeMediaHandle` / `BitmapSourceSafeMILHandle` | 退化成 `IntPtr` / `E_NOTIMPL` | 不影响调用方签名 | `MilNative.cs:9-11` |

**没改的**：13 个导出函数的**签名逐字保留**（`MilNative.cs:5-7`）。这是决策 3 的前提——
将来到 M2 只需把 `exports.cs` 里的 `[DllImport(MilCore)]` 换成对本类同名方法的调用，不改任何调用方。

---

## 6. 测试架构

### 6.1 四套测试的分工

| 套件 | 用例数 | 依赖 | 测什么 |
|---|---:|---|---|
| `Commands.Tests` | **321** | 无 | 命令 round-trip、线格长度（`Marshal.SizeOf<T>` 实测）、118 条覆盖率穷举、矩阵约定、通道状态机、13 个导出函数、3D 资源 |
| `Rendering.Tests` | **31** | 无（Skia CPU） | 12 张 golden 图 + 渲染语义断言 + 字体确定性 + PathGeometry |
| `Windowing.Tests` | **32** | X11（**18** 条需真 server：`[X11Fact]`×9 ＋ `[X11Theory]`×4（其 `InlineData` 共 9 行）〔⏪ `#27` W28B 更正：原写"8 条"；⚠️ **同表用例数 `32` 本波未复算**（要 `dotnet test` 数例），只改了 X 项〕） | 真窗口创建/映射/事件/关闭、`xwd` 截屏断言、文本 6 张 golden、文本确定性 |
| `HelloMil.Tests` | **6** | X11（1 条需真 server） | 端到端：场景构造 → 离屏渲染 → 真 X11 窗口 → 独立进程截屏 |
| **合计** | **390** | | **有 X：390 通过 / 0 失败** |

**无 X 环境的 Skip 约定**（实测，非自报）：

```
env -u DISPLAY dotnet test HelloMil.Tests/    → 5 通过 / 1 跳过 / 0 失败
env -u DISPLAY dotnet test Windowing.Tests/   → 24 通过 / 8 跳过 / 0 失败
```

实现方式：`X11FactAttribute` / `X11TheoryAttribute`（`tests/.../Windowing.Tests/X11Guard.cs:86`、`:99`）
在**特性构造函数**里探测 X server 并据此设 `Skip`。原因写在 `X11Guard.cs:3-15`：xunit v2 不认运行期的
`$XunitDynamicSkip$`，抛 `SkipException` 会被记成 **Failed**；而 `FactAttribute.Skip` 在发现期读取，
特性构造函数恰好也在发现期执行——于是得到了"动态跳过"，且 DISPLAY 不可用时用例压根不会被执行。

判据是"**真的能 `XOpenDisplay`**"（`X11Guard.cs:43-59`）而不是"DISPLAY 非空"。另带 `Category=X11` trait，
CI 可用 `--filter "Category!=X11"` 摘出去。

### 6.2 golden 机制

- **基准图 18 张**：`tests/golden/` 12 张（渲染）+ `tests/.../Windowing.Tests/golden/` 6 张（文本）。
  两个目录**刻意分开**（`Windowing.Tests/TestLayout.cs:3-8` 有说明：混在一起会让两边的 `--update-golden` 互相覆盖）。
- **流程**（`Rendering.Tests/GoldenRunner.cs:23-91`）：渲染 → 实测图**永远**落盘 → 断言栈配平 → 与基准比对 → 失败出 diff 图。
- **判据**：逐像素取 RGBA 四通道**最大**差（不是平均——纯色位移会被大面积背景稀释），
  默认容差 **Δ≤2**（`ImageComparer.cs:41`）；**只要有任何一个像素超阈值就失败**。
- **更新基准**：`WPFGOLDEN_UPDATE=1` / `tests/golden/UPDATE_GOLDEN` 标记文件 / `--update-golden`
  （`GoldenOptions.cs`）。更新模式下重写基准图**并仍然 Pass**，不用 Skip——避免开关从报告里消失。
- **锚定仓库根**：`RepoLayout.FindRoot`（`RepoLayout.cs:34-55`）向上找含 `handoff.md`（兜底 `global.json`）的目录。

> ⚠️ **不要用 `--artifacts-path` 重定向输出目录**：路径解析靠相对程序集位置回退定位 `build/fonts` 与 `tests/golden`。
> 实测加该参数后三套分别炸 2 / 18 / 26 条，全是路径找不到，**不是代码 bug**。

### 6.3 确定性保证（golden 的前提，写在代码里而非文档里）

| 项 | 钉在哪里 | 位置 |
|---|---|---|
| DPI 恒 96 | `RenderContext.FixedDpi`；传别的值直接抛 | `Interfaces.cs:151`、`RenderHarness.cs:63,69-70` |
| 像素格式 | `Rgba8888 + Premul + sRGB` 写死 | `RenderHarness.cs:72-73` |
| 画布初始状态 | 渲染前 `ResetMatrix()` | `RenderHarness.cs:80` |
| 字体封闭 | `build/fonts` 四份 Noto Sans + `SHA256SUMS` 校验；查不到返回 `false`，**不回落系统字体** | `Text/FontSet.cs:52,100-101`、`PackagedFont.cs:40-73` |
| 字体枚举顺序 | 目录枚举后 `Sort(Ordinal)`（文件系统顺序不保证，会影响近似匹配的胜出者） | `FontSet.cs:58-64` |
| AA 开关 | 由调用方显式给，生成与比对必须一致 | `RenderHarness.cs:55`、`Interfaces.cs:164` |
| 栈配平 | 断言 `FinalSaveCount == InitialSaveCount`（**Skia 初始 SaveCount 是 1 不是 0**） | `RenderHarness.cs:32-41` |

---

## 7. 端到端示例：`samples/HelloMil`

### 怎么跑

```bash
Xvfb :99 -screen 0 1280x1024x24 &
cd /workspace/wpf-linux
dotnet run --project samples/HelloMil -- --display :99 --hold 5
# 或只跑离屏：dotnet run --project samples/HelloMil -- --offscreen-only
```

五步输出（`samples/HelloMil/Program.cs:83-144`）：

```
[1/5] 构造 MilChannel 资源表与视觉树 ... OK
[2/5] SkiaRenderBackend 离屏渲染 ... OK（4 条指令，0 条未画出，GlyphRun 跳过=False）
[3/5] 打开 DISPLAY=:99，创建 X11 窗口 ... OK（WindowId=0x200001）
[4/5] Present(frame) 到 X11 窗口 ... OK
[5/5] 独立进程 xwd 截屏 → samples/HelloMil/screenshot.png
```

### 它证明了什么

`samples/HelloMil/screenshot.png`（800×600，15,985 字节）实测颜色直方图：
白底 397,834 / 红 `(200,30,30)` 57,820 / 琥珀 `(235,150,30)` 16,475 / 蓝 `(20,70,200)` 1,762 /
墨绿 `(0,110,70)` 1,534 / 深色文字 977。四个图元 + 文本**全部落到了 X server**。

场景构造见 `samples/HelloMil/TestScene.cs:185-265`：红矩形（`MilDrawRectangle`）+ 蓝对角线（`MilDrawLine`）
+ 文字（`MilDrawGlyphRun`）+ 旋转 20° 平移子 Visual（`MilDrawRoundedRectangle`）。
刻意用**真的 `MilChannel`** 而不是 mock（`:9-14` 有说明）：画刷/画笔/字形在指令流里全是句柄，用 mock 就等于
"我的 mock 和我的一致"，测不到 `TransformResolver` / `SkiaBrush` / `SkiaPen` / `Text/` 的真实路径。

6 条测试断言：`Render_Produces_NonEmpty_Bitmap`、`Render_Contains_Red_Blue_And_DarkText_Pixels`、
`Render_Hash_Is_Deterministic`（连续三次 PNG SHA-256 字节级一致）、`Render_TransformChain_MovesChild_OffOrigin`、
`X11_Capture_From_LiveWindow` 等。

### 它**证明不了**什么

**HelloMil ≠ HelloWpf。** 前者不引用任何 WPF 程序集（`Program.cs:3-11` 明确写着没有 `UseWPF`、
没有 `Microsoft.WindowsDesktop.App`、没有 XAML、没有 `Dispatcher`/`DependencyObject`/`HwndSource`）。
让 `samples/HelloWpf` 在 Linux 上跑起来仍需：① WPF 托管层（约 118 万行 C#、150+ 处 Win32 P/Invoke）能在 Linux 上编译；
② `exports.cs` 的 13 个 `[DllImport(MilCore)]` 接入我们的实现——即决策 3 那一处侵入式改动。
**那是 M2，路线 A1/A2，Avalonia 量级，见 `docs/T9-roadmap.md`。**

---

## 8. 已知边界与债务

| # | 项 | 状态 | 位置 / 证据 |
|---|---|---|---|
| 1 | **测试 flaky**：`MilChannelRegistry` 是进程级静态表 | 根因未除。32 核全并行 12 轮曾 12/12 全绿，但 T3 收尾时 **15 轮抓到 5 次**失败。修法：注册表改实例注入或 `[Collection]` 串行化 | `MilChannel.cs:324-375`；`MilNative.cs:82-92` 全局遍历 |
| 2 | ~~键鼠事件无测试覆盖~~ → **✅ 已闭环（T12）** | `xdotool` 真注入 10 用例 + **突变验证**（偏移改回错误布局 → 10 条全红） | `Windowing.Tests/X11RealInputEventTests.cs` |
| 3 | **`IPresentationTarget.Resize` 后需上层重渲** | X11 resize 是 server 侧动作，内容不会自动缩放。不重渲会留旧尺寸图 + 一块空白。**这是使用契约的一部分，不是实现细节** | `X11PresentationTarget.cs:12-16` |
| 4 | **命令层剩 7 条未实现**（**111/118**） | C 类 6 条（D3D/Shader/Windows 句柄语义，永久不做）+ 1 条 `MilCmdInvalid` 哨兵。⚠️ **2026-09-11 更正**：本条原写"剩 10 条（108/118）"，与 `docs/unimplemented.md` §1 标题的「**7 / 118**」**自相矛盾**；主控按代码复核 `s_notImpl` 表实测 **7** 条 ⇒ **两个数里 §1 是对的**。**这类"从未对齐"（不是"被修好了"）的数字不会因为又修了一处而被发现，只能逐条对码** —— 已纳入 §8.2 的常态检查建议 | `MilCommandLayout.cs`:202-216`；`docs/unimplemented.md:146` |
| 5 | ~~`DISPLAY=:0` 这类无效值会让探测误判~~ → **✅ 已闭环（U10）** | 实测 `DISPLAY=:77`（无 server）：两套测试均优雅 Skip、0 失败；两处探针已统一走 `X11Display.Open`（带重试+失败分类） | `X11Guard.cs`；`HelloMilProbe.cs` |
| 6 | 3D：29 条命令**只解码不渲染** | 解码结果无消费者 | `MilResource3D.cs:8-16` |
| 7 | **Arc 段：真机对照已完成，残差已归因**（降级保留） | U1a 真机像素对照：4 种退化 + 椭圆弧 + sweep×largeArc **全部一致、110 探针全中**；D2/D2′ 我方两格**逐字节相同**（真机 245/16384、最大差 44 纯 AA）；剩余 212px 差归因为**闭合路径 180° 折返处的 miter 裁剪突刺**（真机 = miterLimit×线宽/2），属光栅器 join 规则差异，**非弧线参数化错误**，Skia 无开关可复现 | `docs/U1a-parity-report.md`；`PathGeometryParser.cs:171-179` |
| 8 | ~~`CombinedGeometry.Exclude` 映射存疑~~ → **✅ 已销账（U1a 真机判定）** | 真机 `Exclude` = **A−B（差集）**：B 独占区不填、我们按 `Difference` 处理逐像素一致；反模型 Xor 会填上 B 独占区 `(0,160,96)`（用例有区分力） | `docs/U1a-parity-report.md`；`SkiaGeometry.cs:126-128` |
| 9 | ~~`tests/.../Windowing.Tests/` 下有 `core.*` 转储文件~~ → **文件已清（2026-09-11 主控 `find` 核实为空）**；**"历史 4 个 core 与新 NPE 是否同源"这一子问题已判定为"结构性不可判"并关闭（2026-09-11，T2b 审计）** | 文件层面已清。**`core` 的存在本身说明历史上真有进程崩溃过**，而 2026-09-11 又实测到**新的**崩溃：指针进窗口 → `TextServicesManager.PreProcessInput` → `TextServicesLoader.TIPsWantToRun` **NRE → SIGABRT / core dumped**（已作 P0 派 M7b）。**⚠️ 同源判定已关闭，理由是"比较的另一端不存在"**：core 已清 ⇒ 历史栈不可恢复，无法做同源比对。**要判需要**：① 重新触发并保留 core（开 core dump + 保留文件）；② **或**（T2b 建议、主控采纳）**让新 NPE 稳定复现、自成一条独立 P0，不再与历史 4 个 core 挂钩** —— 历史 core 已不可考，**挂账反而拖住新缺陷的定责**；③ 或提供当时 core 的其它落盘路径 | `find tests -name 'core.*'` 为空；新崩溃见 handoff「鼠标输入」条 |
| 10 | 两套 `RepoLayout` 刻意重复（Rendering.Tests 与 Windowing.Tests 各一份） | 因目录边界不能互相引用，代价是 20 行重复 | `Windowing.Tests/TestLayout.cs:3-8` |
| 11 | ~~无真实 WPF 命令流做 golden binary 比对~~ → **✅ 已闭环（U1b，2026-09-10）** | 真机抓到 **352 条真实 DUCE 命令（含 op5×641）**，逐字节原样流回放 **552 通过 / 0 失败**。过程：代理 DLL（215 导出，真身 106 全在）在 Linux 用 zig 交叉编译（绕开 Windows 侧 360 AV 封锁）；app-local 无效 → 走 `SetDllImportResolver` 重定向。**回放器已按原生语义实现「延迟释放」**（release 标记 → 批次下发后摘除），因此**不再需要任何数据侧改动** | `tests/U1-golden/`；`docs/U1-command-stream-golden-plan.md`；`docs/U1-windows-probe.md` 附录 A |
| 12 | ~~🔴 **P0 · 默认配置下文字整段不画**~~ → **✅ 已闭环（M7b，2026-09-11；主控读图复验）** | **真因（M7b 实测，主控按代码核实）：`Text/FontSet.FromDirectory` 只扫目录顶层**（`Directory.EnumerateFiles(dir,"*.ttf")`，无 `SearchOption.AllDirectories`），而 `/usr/share/fonts` 顶层**一个字体文件都没有**（都在 `truetype/<vendor>/`）⇒ **候选文件=0** ⇒ 面永远解析不到。第二层风险是"请求族名 ≠ 真正要用的 face"。**已派 M7b 做 A（递归）+ B（请求族改用 `SPI_GETNONCLIENTMETRICS.lfFaceName`，与 WPF message font 同源）**；真修法见 #14 | `src/WpfGfx.Linux/Text/FontSet.cs:61-63`；`Interop/MilPresentation.cs:333` |
| 13 | ⚠️ **补丁应用器的"无参=空操作 但 exit 0"假绿**（已加护栏，机制债仍在） | **实测事故**：`patch-presentationcore-textservices`（补丁 M）无参运行只打印"未指定动作"就 `exit 0` ⇒ 波打印 `✅` 而**一个字节没改**，跨两波才被发现。**已加护栏**（波的补丁循环显式匹配空操作标记，双向自测过）。**机制级建议（未做）**：给应用器定个可机检的家族契约（例如要求输出机器可读的 `GENERATED: <path>` / `UNCHANGED:`），波据此判"**声称的产物是否真的存在/被接线**"，而不是靠关键词 | `build/integration-wave.sh`（护栏）；`src/WpfGfx.Linux.Native/tools/patch-presentationcore-textservices.py:182` |
| 14 | ~~🔴 **"字形 id 的面 ≠ 光栅化的面"的真修法（面由 run 决定）**~~ → **✅ 已闭环（2026-09-11 晚）** | 现状：`MILCMD_GLYPHRUN_CREATE.PIDWriteFont`（偏移 8）**被解码后丢弃**（`MilCommandDispatcher.cs:897-913`）、`MilGlyphRun` **无字体字段**、**`MilFontFaceTable.Count = 0`（PC 侧没有任何 `MilFontFace_RegisterFromFile` 调用者）** ⇒ 渲染器只能猜族名。**真修法**：PC 把实际使用的面登记一次并把**句柄**当 `PIDWriteFont` 传下来，MIL 存字段、渲染器优先 `TryResolve(句柄)`（`TextRenderer.MilFontResolver` 钩子本就是为此留的）。**真机佐证**：Windows 上同 face 在 DWrite/Win32 下族名不同、Light 字重 **290** 而非 300、**glyphCount 逐 face 不同** ⇒ glyph id 确实逐 face。**【2026-09-11 晚 · 更新】** **MIL 半边已落地并进部署件**（`Resources/MilResources.cs:419` 的 `PIDWriteFont` 字段 + `Commands/MilCommandDispatcher.cs:899-909` 一行搬运 + 渲染器 seam 走 **`TryResolveExact`**，`Interop/MilPresentation.cs:446`；登记已按 `(path,faceIndex,simFlags)` **幂等**）。**基线读数已更正为 `按句柄命中 0 / 回落族名 0 / 有句柄但解析失败 48`** —— M7b 原先报的 `48/0/0` 是**假命中**：`TryResolve`（`Interop/MilHandleTables.cs:726-735`）在句柄不认识时会**回落 `DefaultTypeface` 并 `return true`**（给轮廓路径的既有契约）⇒ **探针必须用新增的 `TryResolveExact`**（`:747`，不回落），`TryResolve` 原样保留给既有消费者。**PC 半边已派 T1c**：先核 `build/shims/PresentationCore.FontBridge.cs` 的**路径式令牌分配器**（`FontHandleTable.PathTokenAllocator → MilFontFace_RegisterFromFile`）在真应用里走到哪一步（`Status`/`AllocatorCalls`/`NativeAllocations`），再定位真正填 `pIDWriteFont` 的那一处（`GlyphRun.cs:1876` 用的是 `Font.DWriteFontAddRef` ⇒ 看 provider 里它返回的是令牌还是进程内指针）。**验收** = 部署件 census `按句柄命中 48 / 回落族名 0 / 解析失败 0` 且 `不同面数=2`（`0x20000003`×14 + `0x20000004`×66，出处：T2b 逐 run 明细）—— **2026-09-11 更正**：那份是 **R1 落地前**的验收口径；**R1 之后实测 `id0 325→0`、`非拉丁 0→322`、`maxid 3540→63151`、不同面数 = 4**（新增 `0x20000005`=`NotoSansCJK-Regular.ttc#0`、`0x20000006`=`NotoSansCJK-Bold.ttc#0`，两者 `覆盖U+4E2D=是`），四分面 runs `13+57+49+12 = 131` 与整帧闭合，且头条读数（`145 / 未画种类 0 / 938×646 / 507 / 143`）与拉丁档 `T1.73 73/73`、`T2d 1298/1298` 无回归。**依赖关系**：R1（T1d，按码点切多面）落地后，渲染器若仍不知道是哪份面，ids 一样会画错 ⇒ **(乙) 与 R1 必须同时成立** | `Commands/MilCommandDispatcher.cs:897-913`；`Interop/MilHandleTables.cs:747`；`tests/parity/systemfonts/` |
| 15 | ~~**WIC shim 缺 `IWICBitmap_Lock_Proxy`** → `WriteableBitmap` 构造期崩~~ → **✅ 已闭环** | 现象链：`EntryPointNotFoundException` ← `WICBitmap.Lock` ← `WriteableBitmap.TryLock:256` ← `Lock():209` ← **构造期 `:130`**（`nm -D libwpfwic.so` 确认无此导出）。**前置已通**：外来源派发通道已接并 AOT 实证（`GetPixelFormat(backBuffer) hr=0x0 format=Pbgra32`、`GetSize hr=0x0 = 8x8`）⇒ 是在**已验证的通道上再加一个方法** | `build/DirectWrite.Linux/wic-shim/wic_proxy.c`；`.so` ``0d9ae11b…` → **2026-09-11 更正**：现为 `03b67fbcd7c385b6910396165a4db58a` / **70,440 B / 13 个 `Wic*` 导出**（含新增的 `WicShim_DescribeHandle`） |
| 16 | **两个互不相干的"默认字体"面**（PC 侧默认族 vs 渲染器挂哪个面） | ① **PC 侧默认族** = `DefaultFontFamily.SelectFamilyName(...)`（2026-09-11 T1 落地，实测两种目录配置下都选 `Noto Sans`，修掉了旧 `_fontCollection[0]` 漂到 `AR PL UKai CN` 的问题）；② **渲染器挂哪个目录里的哪个面** = `MilPresentation.EnsureGlyphRenderer`（见 #12/#14）。**两者都叫"默认字体"但互不相干 —— 报告/修复时别混成一件**。真机对照：Windows 上 `SystemFonts.MessageFontFamily` **必在** `Fonts.SystemFontFamilies` 里，且是**数据驱动的每用户设置**（SPI = `HKCU\...\WindowMetrics\MessageFont` blob = WPF 值，三处逐字相同） | `build/DirectWrite.Linux/Provider/DefaultFontFamily.cs`；`Interop/MilPresentation.cs:333`；`tests/parity/systemfonts/` |
| 17 | ~~TileBrush 绝对单位 `Viewport` 的原点口径~~ → **✅ 已闭环（T2b，2026-09-11）** | WPF 用**被填充图形的局部坐标系**（原点 = 包围盒左上角），我们原先按**画布原点**解释。真机 A/B 假设检验：局部原点 **194/194** 吻合 vs 画布原点 **20/216**；瓦片原点实测 `(26,26)` = Viewport 原点 `(16,16)`+`(10,10)`。**已修**：`units_vpabs_viewboxabs_tile` **36 点 / 失配 0**，且因果锁死（带修正 0/36 vs 删掉平移 36/36）。**连带重生成 5 张 golden**（旧图锁的是已被真机否定的错误行为），**其余 18 张逐张 sha256 未变** | `src/WpfGfx.Linux/Rendering/SkiaBrush.cs`（`TileViewport`）；真值 `tests/parity/brushes/` |
| 18 | ~~LS 缺口"撞上会是 `E_NOTIMPL`"~~ → **✅ 口径已更正**：`libwpfwin32.so` 里 **`LoAcquireBreakRecord`/`LoCreateLine` 连符号都没有** ⇒ 真走到 LS 是 **`EntryPointNotFoundException`（硬崩）**。**我们先前几处"撞上 `E_NOTIMPL` 就说明走到 LS"的取证设计是错的**；正确装置是 **`LD_PRELOAD` 拦 `dlsym`**（记录 PC 有没有按名字要过 `Lo*`），且装置须先自证不撒谎 | `nm -D src/WpfGfx.Linux.Native/bin/libwpfwin32.so`；`docs/unimplemented.md` §2.7 |
| 19 | ~~🔴 **D3 · 文本回落 LineServices ⇒ 进程 abort**~~ → **✅ 已闭环（2026-09-11；主控实测）** | `SimpleTextLine.Create` 返回 null ⇒ `TextMetrics.FullTextLine` ⇒ `TextFormatterContext.cs:113 LoCreateContext` ⇒ **`EntryPointNotFoundException` ⇒ abort(134)**。**文本稍多的真 WPF 应用 100% 崩**（`WpfTextDemo` 四档全崩）；HelloWpf 因文本框小留在快路径才正常。**诊断**：`grep -rn "HbTextLine\|WpfLinux.Shims" upstream/wpf/src` = **空** ⇒ 我们的 shim **不在那条路上**；**两个站点都要接**：`TextFormatterImp.cs:236-246` 与 **`:309`（`FormatMinMaxParagraphWidth`）**。**已授权 B2 车道把回退接到 `HbTextLineFactory`** | `TextFormatterImp.cs:236-246/309`；`SimpleTextLine.cs:87-127`；`TextFormatterContext.cs:113` |
| 20 | **`ClosedLoop` 的 WIC shim 部署"只拷不覆盖"** | `EnsureWicLibraryAppLocal()` 是 `if (File.Exists(target)) continue;` ⇒ 目标处一旦有旧件**永不刷新**，而 `FindWicLibrary()` 的候选序里"本程序目录"排在前 ⇒ **可能拿 09-10 的旧 shim 跑测试**（实测那份 29,392 B，权威件已 66,152 B）。**主控已删掉过期副本**（删了下次才会从当前源拷）。**机制级修法（2026-09-13 部分落地，T2）**：① **构建期强制同步** —— 新增 `build/MilBridge/tests/Directory.Build.targets` 的 `SyncProviderAuthority`（`AfterTargets="Build"`、**`SkipUnchangedFiles="false"` ⇒ 不依赖增量判断**、`/p:ProviderAuthorityPath` 可覆盖 ⇒ 可被"假权威"验收②证伪）；② **只读校验器** `build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh` 扩到**托管产物**（provider dll / `WpfGfx.Linux.dll`）并定死口径"**`NO-AUTHORITY` 判不了 ≠ 不一致**"（`/release/` 大小写敏感修正后，原先 3 条 MISMATCH 归入 NO-AUTHORITY），**已接进 `publish-milbridge.sh`**（非 PASS 时 `>&2` 大声报、**不改退出码**）；③ 自检 A–D（错 sha 报红 / 正确副本 exit 0 / DIVERGENT 且判 MISMATCH / 无权威 ⇒ NO-AUTHORITY 且 exit 0）。**仍欠**：其它启动目录（`samples/HelloWpf`、`build/DirectWrite.Linux/*Probe/bin/**`）只在各自 `run-*.sh` 内含 build 时才收敛 —— 逐个核过（三个 harness 的 `run-*.sh` 均含 `dotnet build`），**"被别处直接 `dotnet bin/…dll` 启动"的用法出现时要按本节补**。"只拷不覆盖"是这一族假绿的共同形态，与债务 #13 同源 | `build/MilBridge/tests/Directory.Build.targets`；`build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh`；`build/publish-milbridge.sh`；`build/DirectWrite.Linux/REPORT.md` §22；**原始现场** `build/MilBridge/tests/ClosedLoop/Program.cs`（`EnsureWicLibraryAppLocal`/`FindWicLibrary`，"只拷不覆盖"就在这里） |
| 21 | ~~与 `wpfgfx_cor3.so` 同目录的 `libwpfwic.so` 手工同步~~ → **✅ 已闭环（主控，2026-09-11）** | 部署契约要求三者**同目录**，但全仓**没有任何 csproj/脚本**会把 WIC shim 拷进发布目录 ⇒ 那份副本会悄悄过期（实测是 09-10 的 29,392 B）。**已新建 `build/publish-milbridge.sh`**：**绝对** `ArtifactsPath` 发布（修掉"相对路径被按各工程目录解析 ⇒ 产物落错地方而 `PUB_EXIT=0`"那个坑）+ **自动同步权威 shim** + 打印三方 sha + **检测误落目录**。闭环后全仓**只剩 2 份且同 sha**（**2026-09-11 更正**：现为 `03b67fbcd7c385b6…` / **70,440 B / 13 个 `Wic*` 导出**；另新增只读校验器 `check-applocal-sync.sh`，已接进 `publish-milbridge.sh`，并已扩展到**托管产物**（provider dll / WpfGfx.Linux.dll）） | `build/publish-milbridge.sh` |
| 22 | ~~**WIC v2：外来源像素借用**（`WriteableBitmap` 的最后一格）~~ → **✅ 已闭环（2026-09-11 复核）** | v1 传 `pixels=NULL` ⇒ 外来源 `Lock` 诚实返回 `UNSUPPORTEDOPERATION`。**但 `WriteableBitmap` 的契约是"Lock 拿到的指针就是写进去、渲染能看见的那块内存" ⇒ 拷贝一份会让写穿透失效（功能坏掉）⇒ 借用是唯一正确实现**。**已批准 v2**：MIL 侧传 `GetPixels()/RowBytes`（一行），shim 侧借用（`obj_free` 不释放、保留未借像素的拒绝、`CopyPixels` 放开）。**前提**：借用期间 SKBitmap 不移动/重分配 + **注销先于释放**。**闭环证据（2026-09-11 逐条对码）**：`wic_proxy.c` 里 `pixels_borrowed` 出现 **6** 处（`o->pixels_borrowed = pixels ? 1 : 0` / `l->pixels_borrowed = 1` / 仅非借用才 `free`），而"未借像素"的拒绝分支**保留**（v1 契约未被顺手删掉） | `Interop/MilNative.Offscreen.cs`；`build/DirectWrite.Linux/wic-shim/wic_proxy.c` |
| 23 | **图像采样核的定点取整差异（Δ≤1，取舍不是缺陷）** | ImageBrush 现在走 `SKPaint.FilterQuality=Low`（= Skia 能给的最优），与真 WPF 双线性**处处 Δ≤1、Δ>1 的像素为 0**；残留是**定点取整**，不是几何错（几何已由解析模型证明：预测 `#FF926363` vs 真机 `#FF926262`，**Δ=1 LSB**）。**两条被否证的路线（都有实测读数，别再走）**：① **"整片 1:1 离屏（带外扩边）"更差**（`Δ≤1` 从 100% 掉到 97.0%）—— 因为离屏本身还得用 **Skia 的缩放器**去烘，同一个定点误差被烘进去再多一次取样；外扩边只解决"跨瓦片抽头"，而抽头**已由 `Low`+tile mode 解决**。② **`High` 在放大档显著更差**（`>2` 有 2855 个像素）⇒ "`HighQuality` 只在缩小档用 High"这条映射**被实测支持**；但**缩小档的 `High` 与 WPF 的核是否一致仍无证据**。**要逐字节精确的唯一现实路径**是"托管侧用 float 按 WPF 取整规则自定标、Skia 缩放器完全不参与"，代价 = 每画刷一次 O(目标面积) CPU 光栅化 ⇒ **登记为取舍**（与 U14 同类：**"要不要为逐字节精确付一次可见代价"**，等字节级对等成为目标时再回来，届时按 U14 口径量化收益） | `src/WpfGfx.Linux/Rendering/SkiaBrush.cs`；读数见 `build/MilBridge/gen/` 与批次 2 oracle |
| 24 | ~~🔴 **`BitmapSource.DUCECompatiblePtr` → `E_HANDLE`**（应用级阻塞）~~ → **✅ 已闭环（M7b：WIC 物化；主控在 2026-09-11 波后实测 `E_HANDLE`/`LoCreateContext` 各 0 次）** | 打开文本回退后，`WpfTextDemo` **可视树建成、布局走通**，然后崩在呈现/提交：`COMException 0x80070006` ← `HRESULT.Check`（`wgx_render.cs:975`）← `BitmapSource.get_DUCECompatiblePtr()`（`BitmapSource.cs:872`）← `UpdateBitmapSourceResource` ← `AddRefOnChannel` ← `RenderData` ← `UIElement.RenderContent`。**这是 handoff:1660 登记过的 `MILQueryInterface`/bitmap-source 句柄墙**，现已升级为**应用级阻塞**（已派 M7b，`Interop/`） | `upstream/…/Common/Graphics/wgx_render.cs:975`；`BitmapSource.cs:872` |
| 25 | ~~🔴 **D-d · `Image` 卡片空白：PC 交给 MIL 的是一个 1×1 的位图源**（承 #24）~~ → **✅ 已闭环（T2 落方案 A；主控 + T3 双读图）** | 症状：`WpfTextDemo` ④ 卡片的 `Image` 空白；门禁判据④ `feature-color-missing: image_content_g/r/b(0)` 是当前**唯一**的红（T3 正式基线 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`）。**三条已排除**：① **(iii) 用错尺寸字段**（MIL 台账打的 `materialized.Width/Height` 就是按 `GetSize` 建的）；② **(ii) `FormatConverter` 退化**；③ **"它是我们登记的外来源"**（`foreign=0`）。**钉死的证据（进程内取证）**：`WicShim_DescribeHandle` 对 MIL 收到的句柄给出 **`via=slot kind=Frame/Source size=1x1 refs=4 pixels=yes decoded=1`**，而样例自报 `BitmapSource.Create 成功 96x96 Bgra32 stride=384` ⇒ **物化路径忠实，"PC 选错了要交给 MIL 的那个源"** ⇒ **归属 PC/WIC 胶水层**（`BitmapSource.get_DUCECompatiblePtr` → `UpdateBitmapSourceResource` → `AddRefOnChannel`）。**已派 T1c：只定位、不改行为**（渲染/提交流程的行为改动须单独立项）。⚠️ **跨进程探针的边界**：独立进程的 `probe_describe` 只能描述**自己进程**的 shim 表（`0x3` 在探针里是 `E_INVALIDARG`）⇒ 这类句柄问题**必须在应用进程内问** | `upstream/…/Common/Graphics/wgx_render.cs:975`；`src/WpfGfx.Linux/Interop/MilNative.Misc.cs:713`（`DescribeHandle`）；`docs/U2-M7c-report.md` §4.40/§4.41 |

| 26 | 🔴 **模式级债务：「上游发了、我们存了、下一层看不见」= 投影时丢字段**（**已确认 3 个实例**） | **实例**：① `PIDWriteFont`（`MILCMD_GLYPHRUN_CREATE` 偏移 8，见 #14 —— 解码搬了、渲染器优先按句柄取面才修好）；② **变换资源句柄/原始值**（零缩放 CTM 判定时发现"句柄在 `VisualProjection` 投影时被丢掉"，已用旁表 `TransformProvenance` 补）；③ **`AlphaMask`**（`MilCmdVisualSetAlphaMask`=0x23）：`MilCommandDispatcher.cs:215-219` 解码 → `MilVisualNode.cs:14,46` 存字段 → **`Contracts/Interfaces.cs` 的 `MilVisual` 没有该字段、`VisualProjection.cs` 没搬** ⇒ 渲染层永远看不到 ⇒ `UIElement.OpacityMask` **静默失效**（T2b 定位）。<br>**⇒ 判据/检查点（新增字段接入时按此过一遍）**：一个字段要能被消费，必须**同时**过三关 —— ① 契约（`Contracts/Interfaces.cs` 里有它）② **投影**（`Resources/VisualProjection.cs` 显式搬它）③ 消费者（`grep -rn <字段> src/ | grep -vE "Commands/\|Contracts/\|Resources/"` **不许为 0**）。**"解码成功 + 存了字段"不等于"送达"**；只查前两关是本族假绿的成因。<br>**⚠️ 两种查法必须一起用（T2b 的观察）**："**存了但没消费**"是靠 grep 消费点发现的，"**投影没搬**"是靠**读投影函数**发现的；只 grep 消费点会漏掉"**字段压根没进契约**"这一种（`AlphaMask` 正是如此：它连契约字段都没有 ⇒ 消费点 grep **永远是 0 命中**，看不出是"没搬"还是"没建"）。**漏第①步会编译错，漏第②步只会静默默认值、编译不报错 —— 后者才是真危险的。**<br>**配套纪律**：不得静默降级 —— 非纯色遮罩这类做不了的形态要**显式 `RecordNotDrawn`**（进"未画种类"台账），而不是当"没有该属性" | `Commands/MilCommandDispatcher.cs:215-219`；`Resources/MilVisualNode.cs:14,46`；`Contracts/Interfaces.cs`；`Resources/VisualProjection.cs`；`Rendering/SkiaRenderBackend.cs`（T2b 的 4 处点插入 + `Assert.False(root.AlphaMask.IsNull, …)` 锁住该跳） |

| 27 | 🔴 **输入链：`WM_CHAR` 已产出，但 TextBox 收不到（"打字到不了 TextBox"）** —— **未闭环（插桩已就位，等实跑读数）** | **症状**：`--only=textbox-edit` 的注入（`xdotool key --window … ctrl+a` → `type "AB"`）后 `text='seed-文本'`、`changes=0`（TextBox 不变），而窗口是有焦点的。**已钉死的两半**：① **native 侧完全正确** —— `[KEY_DIAG]` 41 行里 `XEV KeyPress`×6、`窗口在表里=1`，且两个键入字符都产出了 `KEY … → WM_KEYDOWN + WM_CHAR`（'A'=0x41、'B'=0x42）；三条 `DROP WM_CHAR 原因`（Ctrl 组合 / Shift 自身 / 释放事件）**全部符合 Win32 语义**；② **`WFP_MSGS … WM_CHAR=0` 不是反证** —— 那条 `[msg]` trace 打在 **dispatch 期**（`src/WpfGfx.Linux.Native/src/win32_msg.c:293` ← `:304 wpf_dispatch_to_window()`），而 WPF 在 **thread-preprocess 期**就把 WM_CHAR 处理掉（`Dispatcher.cs:2199 RaiseThreadMessage` → `HwndSource.OnPreprocessMessage` 的 `case WM_CHAR`，`HwndSource.cs:1852-1871`），标了 handled 就不进 `DispatchMessage` ⇒ **该计数器天生看不见 WM_CHAR（Windows 上同样是 0）**。<br>**⇒ 坏的是 `WM_CHAR → TextInput` 这一腿**（Ctrl+A 那条路是通的：某趟 `selLen=7` = 全选 ⇒ TextBox 确实拿到了键盘）。**头号嫌疑**：`HwndSource._eatCharMessages` —— 每次 `WM_KEYDOWN` 置 `true`（`HwndKeyboardInputProvider.cs:210`），只在"该 KEYDOWN 未被 handled"时当场复位（`:227`），否则靠 `Dispatcher.BeginInvoke(Normal, RestoreCharMessages)`（`HwndSource.cs:2432`）**延后**清；**若它长期为 true，所有 WM_CHAR 被静默吃掉（无异常、无日志）**。次嫌：`IsRepeatedKeyboardMessage`（`HwndSource.cs:2441`，比 `msg/hwnd/wParam/lParam` 四元组）与我们的 `lParam`（`win32_x11.c:574`，**bit30 恒 0**）。<br>**已就位的装置**（缺省关、`WPF_LINUX_INPUT_TRACE=1`、每进程 ≤200 行、**只插入**——按 EDITS 逆序回代后与上游**逐字节相同**）：`src/WpfGfx.Linux.Native/tools/patch-presentationcore-inputtrace.py`，插在 WM_CHAR 分支入口（**在 `if(!_eatCharMessages)` 之外**才看得见"卡住"）、`TranslateChar/OnMnemonic/ProcessTextInputAction` 三步之后、`HwndKeyboardInputProvider` 的 WM_KEYDOWN 进出口、`RestoreCharMessages` 调用点。<br>**判据（先写死）**：入口 `_eatCharMessages=True` ⇒ 卡住；全进程无 `RestoreCharMessages 被调用` ⇒ restore 没跑；入口 False 而 `TranslateChar ⇒ handled=True` ⇒ TranslateChar 吞了；三步皆 False 仍无字 ⇒ 查 `_site.ReportInput`（`HwndKeyboardInputProvider.cs:570`）/ `InputManager.ProcessInput`（`InputManager.cs:506`） | `src/WpfGfx.Linux.Native/src/win32_x11.c:583-598`；`src/WpfGfx.Linux.Native/src/win32_msg.c:293/304`；`upstream/…/InterOp/HwndSource.cs:1852-1871/2432/2441`；`upstream/…/InterOp/HwndKeyboardInputProvider.cs:180-273`；报告 `build/MilBridge/T1c-inputtrace-report.md` |

当前配置：PC `3479253784172bd424a73805…`（4,174,336 B / 16:16:53）｜WindowsBase `30f7637ad7d01aae5f72f648…`｜PF `36abe241bfe5b0a9a4f73e30…`｜桥 `e0d01832a3efea53e6d8e40f04ad136b265e31425e4db087490516cffdfe299c`（4,937,968 B / 16:11:04）｜文本 shim（HbTextLine）`ebccdb1ee65e6f7653da338d70188410615062f825a10969b737ca7d48281bbf`｜`libwpfwin32.so` `e1691fd8440da926cb411a06cba23227189a32be737ff56783299d5ecfad6118`（269,616 B，全仓 4 份同 sha）｜WIC shim `03b67fbcd7c385b6910396165a4db58a`（70,440 B / 13 导出）。门禁 `verify-all.sh` 9/9、843 通过 / 2 跳过 / 0 失败；集成波波前==波后 `143a9f799fe22159020dd55991e7a185982a38c0bd02755e8bea5cd48b860548`。

| 行 | 处置 | 证据 |
|---|---|---|
| #12 P0 文字整段不画 | **闭环** | 根因 = `FontSet.FromDirectory` 只扫顶层（`/usr/share/fonts` 顶层无字体文件）；改**递归** + 请求族改走 `SPI_GETNONCLIENTMETRICS.lfFaceName` + 兜底；主控**读图**确认文字上屏、`未画种类 0` |
| #14 字形 id 的面 ≠ 光栅化的面 | **闭环** | (乙) **A/B 翻转**：开档 `按句柄命中 48 / 0 / 0`（2 面）⇄ 关档 `0 / 0 / 48`（1 面）⇒ 排除"另有登记者"；**三点对齐** `token ↔ 登记 (path,faceIndex) ↔ 逐 run pid ↔ 渲染器实际面`；R1 后新增 **`0x20000005`=`NotoSansCJK-Regular.ttc#0`、`0x20000006`=`NotoSansCJK-Bold.ttc#0`（`覆盖U+4E2D=是`，runs 49+12）**，四分面 runs `13+57+49+12 = 131` 与整帧闭合 |
| #15 缺 `IWICBitmap_Lock_Proxy` | **闭环** | `nm -D` 见到 `IWICBitmap_Lock_Proxy` / `IWICBitmapLock_GetDataPointer_STA_Proxy` / `IWICBitmapLock_GetStride_Proxy` |
| #19 D3 文本回落 LS ⇒ abort | **闭环** | 波后应用日志 `LoCreateContext` **0 次**（旧行为：27 次 ⇒ `abort(134)`）；**阴性对照**：`WPF_LINUX_TEXTLINE_FALLBACK=0` 仍当场崩 ⇒ 这条链确实在起作用 |
| #24 `DUCECompatiblePtr → E_HANDLE` | **闭环** | 波后应用日志 `E_HANDLE` / `80070006` **0 次**（M7b 的 WIC 物化把"句柄不可查"变成"拷一份"） |
| #25 D-d（`Image` 空白） | **闭环** | 根因 = **上游 `BitmapSource.cs:773-795` 有意的 1×1 解码探针 + 我们 shim 不支持子矩形 `CopyPixels`**（返回 `UNSUPPORTEDOPERATION`）⇒ 上游 `RecoverFromDecodeFailure` 换成 1×1 `Pbgra32` 占位。**修法 A**（shim 支持任意 `prc`，T2 落；`probe_subrect` 6 条全绿 + 行基址 off-by-one 突变有牙）⇒ 实测 `materialize尺寸 1x1 → **96x96**`、`fmt …c910(Pbgra32) → **…c90f(Bgra32)**`、`COPY_PIXELS_REFUSE = 0`；**主控与 T3 各读一次图**确认 ④ 卡位图与 ⑤ 卡三形状都画出来了。验收门禁随之**首次 PASS（default/env 两档 6/6）**。**已知偏差（登记、非缺陷）**：`cbBufferSize` 不足仍返回 `E_INVALIDARG`（本移植既有语义），与 WIC 文档的 `INSUFFICIENTBUFFER` 不同 —— 未拿到"有调用方依赖该码"的证据前不得改 |
| **新增** | ~~**多行段落摞在同一基线**~~ → **✅ 已闭环（T1d 修，主控成对取证）** | **根因**：`HbTextLine.Draw` **丢弃了宿主传入的行 `origin`**（上游语义 `SimpleTextLine.cs:585` `run.Draw(dc, x + origin.X, origin.Y + Baseline, …)` 必须带上）⇒ 折行段落每行画在同一 y。**推理方向被否证过两次才落地**（"上游放同一 Y" ✗ T2b｜"上游那条路没带上" ✗ T1c）——**两次否证都在改代码之前**。<br>**修法**：把 `origin` 烘进每张 `GlyphRun` 的基线原点（落点即 `MilGlyphRun.Origin`；`BaselineOrigin` 是 init-only 故不能原地改；`(0,0)` 时返回原对象 ⇒ 首位行逐位不变）。<br>**证据**：① 卡同段 5 行 `devY` `175.486`（五个全等）→ `175.486/192.462/209.438/226.414/243.390`（增量 16.976 设备像素 = 一个行高）；真宿主 `hostOrigin` 递增且 `Δ = firstRunOriginY − (hostOriginY + Baseline) = 0`；**读图** ① 卡 6 行分开、② 卡不叠字；`T1C_CENSUS_SUMMARY`（`id0=0/nonlatin=322/maxid=63151`）与 `run.sh tline` 全项不变；`verify-all` 9/9。**验收侧新增判据⑦**（`WPTD_LINE_ADVANCE`，阈值用实测定 10，带变异开关，NA 显式打印） |
| **新增** | **`Extent` 语义（T1d 修）** | 真值 = **墨迹盒高度**（上游 `SimpleTextLine.cs:1796-1802` `ComputeInkBoundingBox` + `:1071-1083` 注释 "height of the actual black"）；**实测否证 HarfBuzz extents 口径**（HB Latin 16.0800 / CJK 15.2320 vs 真值 18.0800 / 18.0859），改用上游同一条公式 ⇒ `T2e extent_ok 0/10→5/10`、`T2d Extent 0/1298→1259/1298`，`Height/Baseline` 仍 1298/1298。**消费者已核**：`TextLine.Extent` 全仓只有 `FormattedText.cs:1752/1779`（黑盒度量，报告量）⇒ **不牵动应用布局**。**CJK 5 例仍红**（根因在 provider：`Provider/LinuxFontFace.cs:295-299` 用 `glyf` 表取 ink box，而 **CJK `.ttc`/`.otf` 是 CFF** —— 实测 `NotoSansCJK-Regular.ttc` `glyf=0 B` / `CFF=15,458,582 B`；对照 `arphic/ukai.ttc`、`uming.ttc` 虽是 CJK 名字却是 **glyf**）⇒ 已派 T2 修 provider（**三次未落成、已回滚，Provider 保持干净**；确切调用图已取得：4 处 + 核心内自调用） |
| **新增** | **零缩放 CTM = 上游输入**（结案，**非缺陷，未改行为**） | 原始字段证据：`0x8d`/`0xa4` 挂的都是 `MilScaleTransform(ScaleX=0, ScaleY=0)`，**解析后矩阵与原始值一致** ⇒ `TransformResolver` 无过；影响面 = 4 个局部 7×4、clip 1×1 的小图标 |
| **新增** | **验收门禁的 X 复用假红**（"仪器在说谎"第 15 个成员） | `verify-all.sh` 原先"只要 `pgrep -x Xvfb` 有进程就复用"却**无条件** `export DISPLAY=:99`，而当时活着的 Xvfb 在 `:98` ⇒ `ManagedLayer` 端到端输入用例**假红**（`CreateWindowEx 1400`）+ `Windowing/HelloMil` **假跳过**（`26+13 / 18+1` → 修后 `44+0 / 19+0`）。**已改为 `xdpyinfo` 验证通过后才 export**；修后门禁 **9/9、828 通过 / 2 跳过 / 0 失败** |



---

### 8.2 2026-09-11 · 文档逐条对码审计（T2b 只读审计，主控按代码复核后落笔）

**动机**：**陈旧的结论也是假绿**。`docs/**` 是接手的第一入口之一；若它写着"X 未实现"而代码早已实现（或反之），下一个人就会照着错清单干活。

**审计计数**：✅ 过期/已闭环 **5** ｜ 🔴 仍成立 **9** ｜ ❓ 判不了 **3**（细则见 `handoff.md` 本轮条）。

**本轮已改正的 5 条**（每条带代码/读数证据，且主控独立复核过）：

| 位置 | 原文问题 | 更正 |
|---|---|---|
| §8 #4 | 「剩 **10** 条（108/118）」 | 实测 `s_notImpl` 表 **7** 条 ⇒ **111/118**；且与 `unimplemented.md` §1 标题「7 / 118」**自相矛盾** |
| §8 #15 | 证据行「`0d9ae11b…`（**11** 个 `Wic*` 导出）」 | 现 **`03b67fbc…` / 70,440 B / 13 导出** |
| §8 #21 | 证据行「**66,152 B / 11 导出**」 | 同上更新；并补记校验器已接进发布脚本、已扩展到托管产物 |
| §8 #22 | WIC v2 借用读起来像"待做" | **已落地**（`pixels_borrowed` 6 处；未借像素的拒绝**保留**）⇒ 标 ✅ |
| §8 #14 | 基线「解析失败 48」、验收「面数=2」 | 那份是 **R1 前**口径；R1 后 **`id0 325→0`、`非拉丁 0→322`、`maxid→63151`、面数 = 4** |

**❓ 判不了 3 条（明说缺什么，不猜）**：#9（历史 `core.*` 是否与新 NRE 同源 —— core 已清，缺回溯）；`unimplemented.md` §2.6（`build/fonts-ui/UI-NoLayout.ttf` 是否**仍是**默认 UI 字体 —— R1 多面整形后可能已换，**未查**）；§2.7（"缺 26 条 LS" —— 按文档复述，**未逐条 `nm` 复核**）。

**⇒ 要固化的建议（T2b 提、主控采纳）**：**"过期"与"从未对齐"是两类**。前者会随"又修了一处"被发现；**后者（同一件事在文档里有两个数）不会** —— 例如 #4 的「10 条」与 §1 标题的「7 / 118」并存了好几个波次，谁也没红。
**落地形态**：对**代码可算的量**（未实现命令数、导出数、副本 sha/体积…），文档**引用命令/字段**而不是硬写数字；并把"文档内部自相矛盾"纳入**交付前的一次便宜检查**（跑 `NotImplCount`、`nm -D | grep -c ' Wic'` 之类与文档比对）。

**第二轮：把审计里"判不了"的 3 条全部收口**（T2b 只读复核 → 主控落笔）：**✅ 过期 1 ｜ 🔴 仍成立 1 ｜ ❓ 结构性不可判 1**

| 条目 | 原状态 | 收口结论 | 证据 |
|---|---|---|---|
| `unimplemented.md` §2.6（默认 UI 字体 = 剥离 GSUB/GPOS 的派生件） | ❓ 判不了 | **✅ 已过期** ⇒ 已改写该节 | `build/fonts-ui/UI-NoLayout.ttf` 仍在（332,736 B），但引用面**只在测试/探针档位与一处注释**（`t1b-live-window.sh:8,72`、`t1d-probe.sh:12,70,87`、`t1c-census.sh:16`、`MilPresentation.cs:388-389` 注释）⇒ **无生产路径把它当默认 UI 字体**；它是**诊断档位**（`0` 个 CJK 码点 ⇒ 结构性无法覆盖中文）。**仍欠一格**：`ResolveSystemFontDirectories`/`Win32UiFont` 那条链未逐行核 ⇒ "默认族现在解析成什么"需读码或一次运行期读数 |
| `unimplemented.md` §2.7（LS 缺 26 条） | ❓ 判不了（原标注"按文档复述"） | **🔴 仍成立，且文档数字准确** ⇒ 已加"复核于 2026-09-11" | `LineServices.cs` 的 `EntryPoint` 总数 **27**（与文档一致）；`nm -D libwpfwin32.so` 458 个符号；逐条 `comm` ⇒ **存在 1（`LoGetEscString`）/ 缺失 26**。**审计者原先那句"未复核"已撤回** |
| `ARCHITECTURE.md` #9（历史 4 个 `core.*` 与新 NPE 是否同源） | ❓ 判不了 | **❓ 结构性不可判 ⇒ 关闭该子问题** | **比较的另一端不存在**：core 已清 ⇒ 历史栈不可恢复。**要判需要**：重触发并保留 core，**或**（采纳）**让新 NPE 自成一条独立 P0、不再与历史 core 挂钩**（历史 core 已不可考，挂账反而拖住新缺陷定责） |

---

## 9. 附：读代码才能发现的架构事实（handoff 未记录）

按"接手的人最容易踩到"排序：

1. **`MilCmdRenderData` 会被解码两次**。一次在分发时（`MilCommandDispatcher.cs:453`），
   一次是 `VisualProjection.ResolveContent` 的 `??=` 兜底（`VisualProjection.cs:77`）——
   为的是"命令流只改了 `Data` 而没走分发"的情况。两处都指向同一个 `RenderDataDecoder`。
2. **命令层与渲染层之间有一条原始字节旁路**。`MilDrawInstruction` 装不下的指令（`*Animate`、Guideline、
   `PushEffect`、`PushOpacityMask`）只记 `Command`，原始字节留在 `MilRenderData.RawPayloads`，
   由渲染层按下标回读（`MilRenderData.cs:41` ↔ `SkiaRenderBackend.cs:148`）。**两边按下标一一对应是硬约束**，
   少一条会让后面的指令读到错位数据（`TestScene.cs:337-339` 显式补 `Array.Empty<byte>()` 就是这个原因）。
3. **通道句柄是 `GCHandle` 而非内核对象**，因此不能跨进程；`WgxConnection_SameThreadPresent` 必须遍历进程级静态表
   （`MilNative.cs:82-92`）。这既是架构选择也是 flaky 的来源。
4. **`RenderContext` 是 `sealed`**，直接导致资源解析只能做成后端构造期注入（`MilResourceProvider.cs:5-9` 有说明）。
   将来要往渲染上下文里加参数，得先动契约——而"改契约 = 全队阻塞"。
5. **3D 解码结果挂在 `ConditionalWeakTable` 弱键附加表上**（`MilResource3D.cs:346-348`），
   是一种"不越界改他人目录"的绕行手法：不改 `Resources/` 一行、资源释放后表项自动回收。
6. **`IMilChannel` 的写入方法返回 `void`**，无法回传 HRESULT；违反状态机时抛异常而非返回错误码
   （`MilChannel.cs:256-302`，带 `ContractErrors` 计数）。与 L1 的 HRESULT 风格是两套。
7. **存在两套同义类型**：`DUCE.ResourceType/ResourceHandle`（`Interop/Duce.cs`）与
   `MilResourceType/MilResourceHandle`（`Contracts/`）。取值与宽度逐项一致，桥接层零成本转换
   （`MilResourceTable.cs:143-177`）。改名/改值必须两边同步。
8. **HelloMil 的字形 id 用与渲染器同一份 `SKTypeface` 生成**（`TestScene.cs:174`）——
   因为 `MilGlyphRun` 不带字体身份，字形 id 又字体相关，二者必须同源，否则画出来全是 `.notdef`。
9. **`XPutImage` 前必须把 `XImage.data` 置空再 `XDestroyImage`**（`X11Window.cs:426-430`）。
   否则 Xlib 会对托管堆指针调 `free`，直接崩。
10. **`X11Window.Resize` 后必须 `XSync`**（`X11Window.cs:159-161`）：否则紧接着的 `XPutImage`
    可能画在还没变大的窗口上，被裁掉一块。同理 HelloMil 截图前 `target.Sync()` 而非 `Flush()`
    （`Program.cs:127-129`），因为 `xwd` 走的是另一条连接。

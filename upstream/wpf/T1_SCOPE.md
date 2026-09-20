# T1 Spike 范围评估：最小 DUCE stub 后端 + Web 输出可行性

> 依据：`DUCE_INVENTORY.md` 与 `winbase_pinvoke.json` 的静态分析结果
> 仓库：`/workspace/wpf2web/upstream-wpf/src/Microsoft.DotNet.Wpf/src/`
> 目标：fork 托管层，仅替换 MilCore/WpfGfx 非托管渲染为"DUCE 兼容后端"，使 WPF 程序在 Linux 编译并以 Web 呈现。

---

## 1. 替换架构定位

```
 WPF 托管层（保留）
   PresentationFramework / PresentationCore / WindowsBase / System.Xaml / PresentationBuildTasks
        │  视觉树 / 布局 / 属性系统 / 动画 / 输入路由  —— 全部保留
        ▼
   DUCE 边界（MS.Win32.PresentationCore.DUCE + Channel + IResource）
        │  句柄 + 渲染指令字节流（MILCMD / RenderData）
   ───────────────── 替换分界线 ─────────────────
        ▼
   原：wpfgfx / MilCore（Windows 非托管，不可在 Linux 编译）
   新：DUCE stub 后端（本 Spike 要实现的接口面）
        ├─ 通道传输：把 Channel 字节流拦截为"渲染指令 JSON"
        ├─ 资源表：ResourceHandle → Web 侧对象（Canvas/Skia）
        └─ MILCMD 解释器：143 条命令 → Canvas 2D / Skia 指令
```

判定原则：**托管层只通过 `DUCE.Channel` 的有限方法 + `DllImport.MilCore`（110 处）与非托管层对话**。只要我们让这 110 处 P/Invoke 与一个自制后端对接（而不是真的去 P/Invoke wpfgfx），上层即可零改动运行。

---

## 2. 最小 DUCE stub 后端接口面估算

### 2.1 必须实现"真实行为"的接口（核心，不可占位）

#### A. `DUCE.Channel`（Common/Graphics/exports.cs:320）
通道原语必须真实工作，因为上层所有 `UpdateResource` 都经它写指令：

| 方法 | 必须行为 |
|---|---|
| `SendCommand` / `BeginCommand` / `AppendCommandData` | 把 MILCMD + 参数写入可拦截的字节流（或直送解释器） |
| `Commit` / `CloseBatch` | 冲刷一批指令到当前帧 |
| `SyncFlush` | 同步提交（用于布局确定的同步上屏） |
| `Present` | 触发一帧合成/呈现 |
| `CreateOrAddRefOnChannel` / `ReleaseOnChannel` / `DuplicateHandle` | **资源句柄生命周期管理**（ResourceHandle 表：create/destroy/refcount） |
| `IsConnected` / `IsSynchronous` / `IsOutOfBandChannel` | 状态查询 |

#### B. `DUCE.IResource`（Common/Graphics/exports.cs:2508）
每个可视对象实现 `UpdateResource(DUCE.Channel)`、`AddRefOnChannelCore`、`ReleaseOnChannelCore`、`GetHandleCore`。stub 后端需消费这些调用，把对象登记进资源表。

#### C. `MilCoreApi`（UnsafeNativeMethodsMilCoreApi.cs:14，44 处）—— 关键子集
| 函数 | 必须行为 |
|---|---|
| `WgxConnection_Create` / `WgxConnection_Disconnect` | 建立"连接/传输"（在 Linux 指向 stub 后端而非真实 Transport） |
| `MilCompositionEngine_Enter/ExitCompositionEngineLock` / `Enter/ExitMediaSystemLock` | 锁——可用托管 `lock`/Monitor 实现 |
| `MilVersionCheck` | 返回兼容版本号 |
| `MILCreateStreamFromStreamDescriptor` | 流桥接（如有 Image/Video 资源） |
| `MilUtility_*`(GetTileBrushMapping 等) | 笔刷映射工具——需真实数学实现（供 TileBrush 等） |

> 其余 `MilCompositionEngine_*`（通知/分区间）多数可先桩或简单实现。

#### D. `Composition`（Composition.cs:8 处）—— 资源创建/删除命令
`MilResource_Create`/`Delete` 类包装必须真实：把 `DUCE.ResourceHandle` 映射到后端资源对象。

#### E. MILCMD 解释器（Common/Graphics/wgx_core_types.cs:600，143 命令）
需覆盖"可上屏必需"子集（其余可占位）：

| 分组 | 命令 | 数量 | 是否必需 | Web 映射 |
|---|---|---|---|---|
| Visual/Target 管理 | `MilCmdVisual*`, `MilCmdHwndTarget*`, `MilCmdGenericTarget*`, `MilCmdTarget*` | ~30 | 必需（场景图） | Visual→DOM 层 / Canvas 合成层 |
| 资源定义 | `MilCmd*Brush`(Solid/Linear/Radial/Image/Drawing/Visual/BitmapCache)、`MilCmdPen`、`MilCmdGeometry*`、`MilCmdGlyphRunDrawing` 等 | ~40 | 必需 | 对应 Canvas/Skia 对象 |
| **Render Data 绘制原语** | `MilDrawLine/Rectangle/RoundedRectangle/Ellipse/Geometry/Image/GlyphRun/Drawing/Video`(含 Animate)，`MilPushClip/OpacityMask/Opacity/Transform/GuidelineSet/Effect`，`MilPop` | **25** | 必需（核心绘制） | Canvas 2D / SVG / Skia 1:1 |
| 媒体/3D/高级 | `MilCmdMediaPlayer`、`MilCmdD3DImage*`、`MilCmdViewport3D*`、`MilCmdVisual3D*`、`MilCmdEffect` 等 | ~30 | **可占位/后续** | 3D/视频/D3D 暂不支持，返回占位 |

⇒ **stub 后端"真实行为"最小集 ≈ Channel 全方法(~26) + IResource 协议 + MilCoreApi 关键 ~10 + Composition 资源生命周期 + MILCMD 可上屏子集(~95/143)**。

### 2.2 可"返回占位/桩"的接口（不阻塞首版）

- `EventProxy`/`MediaContextNotificationWindow`（2+2 处）：通知回调，先空实现。
- `MILQueryInterface`/`MILAddRef`（COM 生命周期，2 处）：返回固定值。
- `MilCmdEtwEventResource`（0x19）：ETW 跟踪，空实现。
- `MilCmdChannelRequestTier`/`PartitionSetVBlankSyncMode`/`PartitionNotifyPresent`：呈现模式/DWM 同步，桩。
- D3DImage / MediaPlayer / Video / Viewport3D / 3D 旋转相机 / PushEffect / BitmapCache 高级效果：占位返回，首版不渲染。
- `StreamAsIStream`（1 处）：流桥接，按需。

### 2.3 接口面规模小结

| 层 | 真实行为 | 占位/桩 | 备注 |
|---|---|---|---|
| DUCE.Channel + IResource + 资源表 | ~26 + 协议 | — | 后端骨架 |
| MilCoreApi（44） | ~10 关键 | ~34 | 多数锁/通知可桩 |
| Composition（8） | 8 | 0 | 资源生命周期 |
| MILCMD（143） | ~95（绘制+场景图+资源） | ~48（3D/媒体/ETW/效果） | 25 条绘制原语全必需 |
| 合计（DUCE 侧） | **~139** | **~82** | 与 110 处 P/Invoke 相呼应（P/Invoke 是入口，命令枚举是语义） |

---

## 3. Web 输出（渲染指令 JSON → Canvas）映射可行性

### 3.1 映射链路
```
WPF Visual 树
  └─(UpdateResource)→ DUCE.Channel 字节流 (MILCMD + 资源句柄)
        └─[stub 后端拦截]→ 渲染指令 JSON：
            { "target":<handle>, "visuals":[ {handle, transform, clip, opacity, children:[...]} ],
              "resources":{ <handle>: {type:"SolidBrush",...} | {type:"Geometry",...} },
              "draw":[ {cmd:"MilDrawRectangle", ...}, {cmd:"MilPushTransform",...}, {cmd:"MilPop"} ] }
        └─[前端]→ Canvas 2D / SVG / Skia 重绘
```

### 3.2 可行性结论
- **指令本身是声明式、序列化的**，与"立即模式 GUI"天然契合 Canvas/SVG/Skia ⇒ **映射可行且直接**。
- **25 条 Render Data 绘制原语**可 1:1 落到 Canvas 2D（`lineTo/fillRect/arc/fill()/clip()/save/restore/setTransform/drawImage/fillText`），GlyphRun 用 Skia/HarfBuzz 文本。
- **资源（Brush/Pen/Geometry/Transform）** 为可复用对象，建表后按 handle 引用，符合 Web 合成模型。
- **Visual 树 + Target + 脏区** 对应前端分层/增量重绘；`MediaContext` 的脏区收集逻辑（托管侧）可直接保留，只需把"提交到 MilCore"换成"提交渲染指令 JSON 到前端"。

### 3.3 主要风险点（须在后续 Spike 验证）
1. **资源句柄生命周期**：`CreateOrAddRefOnChannel`/`ReleaseOnChannel` 的引用计数语义须精确复刻，否则内存/渲染错乱。
2. **Transform/Clip/Opacity 嵌套栈**：MilPush*/MilPop 的栈语义须与 Canvas save/restore 严格对应。
3. **GlyphRun 文本保真**：DirectWrite → HarfBuzz/FreeType 的度量差异会导致换行/字距不一致（见 R1 文本部分）。
4. **脏区/增量重绘**：`MediaContext.Render` 的批处理时机须对齐前端 rAF，避免闪烁。
5. **R1 窗口/输入**（见下）：若首版目标是"纯 Web 渲染"，可把 Hwnd 概念替换为"虚拟 surface"，从而**绕过大部分 user32 消息循环依赖**，大幅降低 R1 工作量。

---

## 4. R1 风险量化结论（对 T1 的影响）

- **R1 真实 Win32 表面 ≈ 230+ 条 P/Invoke**（`Shared/MS/Win32/` 链接进 WindowsBase），其中 `user32` 128 为最大头。
- **但若采用"虚拟 surface + Web 呈现"策略**：`HwndWrapper`/`HwndSubclass`/`ComponentDispatcher` 的 HWND 依赖可改为"无 HWND 的离屏合成目标"，消息循环由前端事件驱动回灌 ⇒ **R1 窗口/消息循环工作量可显著收敛**，仅剩：
  - `Dispatcher` 消息泵（`PresentationNative` 的 `MsgWaitForMultipleObjects` 类原语，39 处）→ 用托管 `Task`/epoll 等待替换；
  - 输入路由（`ComponentDispatcher`/`HwndSubclass` 转发）→ 前端事件直接注入 `InputManager`；
  - 文本（DirectWrite→HarfBuzz/Pango，见 `DUCE_INVENTORY.md` 2.4）。
- **可裁剪**：`msdrm`(49)/`PresentationHost`(14)/`winspool`(2)/`urlmon`/`wininet`(7)/`shell32` 等共 ~102 条与 UI 渲染无关，直接桩或删功能。

### R1 工作量分级（首版）
| 优先级 | 内容 | 条数(估) |
|---|---|---|
| P0 | Dispatcher 等待原语、虚拟 surface 替代 HWND、输入回灌 | ~50 |
| P0 | 文本：HarfBuzz/FreeType 替代 DirectWrite | （独立模块） |
| P1 | 其余 user32/kernel32 窗口/线程（如确需真实窗口） | ~100 |
| 裁剪 | msdrm/PresentationHost/打印/Shell/网络 | ~102（桩/删） |

---

## 5. T1 Spike 建议交付（下一步）

1. 在 fork 中新建 `WpfWeb.DUCEBackend` 项目，实现 `DUCE.Channel`/`IResource` 拦截 + `MilCoreApi` 桩 + `MILCMD` 解释器（先覆盖 25 条绘制原语 + Visual/Target 管理）。
2. 输出"渲染指令 JSON"契约（上文 §3.1 结构），由独立前端（Canvas）消费，验证 `Button/TextBlock/Image/Border` 等基础控件可绘制。
3. 文本模块先接 HarfBuzz，验证 `TextBlock` 排版/换行。
4. 评估"虚拟 surface"策略下 `HwndWrapper` 改造量，给出 R1 最终工作量。

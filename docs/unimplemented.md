# M1 未实现登记（mil-core 组 · T2/T3）

> 本文件登记 `WpfGfx.Linux` 中**明确返回 `E_NOTIMPL`** 的协议面。
> 目的：让"没做"这件事是显式、可查、可计数的，而不是散落在代码里变成静默丢命令。
>
> 例外：**§2.4 登记的是 4 条"返回成功码但语义只落一半"的条目**（M7a 引入）。
> 它们不在 `E_NOTIMPL` 台账里，但同样需要显式可查——否则最危险的失败模式
> （"看起来成功了，其实什么都没接"）会重新变成散落在代码里的隐性债务。
>
> 与本文档对应的机械校验：
> - `tests/.../Commands.Tests/CommandCoverageTests.cs` —— 穷举 118 条命令字，
>   凡返回 `E_NOTIMPL` 的必须能在 `MilCommandLayout.NotImplementedCommands` 里查到，反之亦然。
> - `tests/.../Commands.Tests/tools/verify-cmd-layout.py` —— 已移植的 103 个线格结构体
>   与上游 `Generated/wgx_commands.cs` 逐 `FieldOffset` 比对（上游共 108 个，共有 102 个；
>   移植侧多出的 1 个是 `MILCMD_BITMAP_SOURCE`——上游 C# 生成版没有它，只有 C++ 头里有；
>   移植侧缺失的 6 个是本文件 §1 的 C 类）。
> - `MilNative.ExportManifest` / `MilNative.NotImplExportNames` / `MilNative.MissingExports()`
>   —— **导出函数章（§2）**的机械校验入口，覆盖 108 个 `DllImport(DllImport.MilCore)`
>   导出名及其实现深度；条文与代码的逐条对应见 §2.0。
>
> **章节更新时间**：§1 顶层命令由 T3 于 2026-09-04 定稿；
> **§2 导出函数由 M7a 于 2026-09-10 更新**（3 条 → 29 条，并新增 §2.4 / §2.5）。

---

## 0. 分类结果（T3 收尾）

对 38 条 E_NOTIMPL 逐条查了上游 `Generated/wgx_commands.cs` 的字段类型与
`PresentationCore/System/Windows/Media3D/Generated/*.cs` 的 `MarshalTo` 实现，
按「**载荷本身能否在 Linux 上解释**」这条线切分：

> **判据**：载荷字段是 POD（double / float / 句柄 / 定长向量矩阵）→ 命令可完整解码，
> 属 A 类；载荷是 COM 接口指针、Windows HANDLE、原生对象指针、HLSL 字节码 →
> C 类；载荷可解但**语义落点依赖尚不存在的子系统** → B 类。

| 类 | 条数 | 命令字 | 处置 |
|---|---|---|---|
| **A · 可实现** | **29** | 0x57–0x6b（21）+ 0x29–0x30（8） | **已实现**：结构体 + 解码 + 状态落地 |
| **A′ · 载荷重定义** | **2** | 0x0c, 0x0d | **已实现**：0x0c 的 COM 指针列改作位图令牌（见 §0.1） |
| **B · 有前提** | **1** | 0x17 | 登记清楚，本次不做 |
| **C · 永久不做** | **6** | 0x0a, 0x0b, 0x6c, 0x70, 0x3b, 0x3c | 划掉（handoff 决策 4 + 无 Linux 对应概念） |

```
29 (A) + 2 (A′) + 1 (B) + 6 (C) = 38  ✓
118 = 100（前两轮：79 原有 + 21 条 3D 资源）
        + 8（3D 视觉树）+ 2（0x0c/0x0d 位图源）+ 7（B+C）+ 1（MilCmdInvalid 哨兵）
已实现 = 110 / 118
```

### A 类 · 29 条（0x57–0x6b 与 0x29–0x30）

**为什么算 A**：这一整段的字段只有 `double`、`MilPoint3F`(12B)、`MilQuaternionF`(16B)、
`MilColorF`(16B)、`DUCE.ResourceHandle`(4B)、`MilRect`(32B) 和 `D3DMATRIX`(16×float=64B)。
`D3DMATRIX` 名字带 D3D，但**它就是一个 16 浮点数的纯数值矩阵**（`wgx_core_types.cs:963`），
不含任何 COM/D3D 对象引用。因此这与已实现的 2D 画刷/变换命令**同构**。

#### 0x57–0x6b（21 条，上一轮完成）

| 命令字 | 命令名 | 固定长度 | 变长 |
|---|---|---|---|
| 0x57 | `MilCmdAxisAngleRotation3D` | 36 | |
| 0x58 | `MilCmdQuaternionRotation3D` | 28 | |
| 0x59 | `MilCmdPerspectiveCamera` | 96 | |
| 0x5a | `MilCmdOrthographicCamera` | 96 | |
| 0x5b | `MilCmdMatrixCamera` | 140 | |
| 0x5c | `MilCmdModel3DGroup` | 16 | ✔ ChildrenSize = 4×N |
| 0x5d | `MilCmdAmbientLight` | 32 | |
| 0x5e | `MilCmdDirectionalLight` | 48 | |
| 0x5f | `MilCmdPointLight` | 96 | |
| 0x60 | `MilCmdSpotLight` | 136 | |
| 0x61 | `MilCmdGeometryModel3D` | 24 | |
| 0x62 | `MilCmdMeshGeometry3D` | 24 | ✔ 4 段定长数组（见下） |
| 0x63 | `MilCmdMaterialGroup` | 12 | ✔ ChildrenSize = 4×N |
| 0x64 | `MilCmdDiffuseMaterial` | 44 | |
| 0x65 | `MilCmdSpecularMaterial` | 36 | |
| 0x66 | `MilCmdEmissiveMaterial` | 28 | |
| 0x67 | `MilCmdTransform3DGroup` | 12 | ✔ ChildrenSize = 4×N |
| 0x68 | `MilCmdTranslateTransform3D` | 44 | |
| 0x69 | `MilCmdScaleTransform3D` | 80 | |
| 0x6a | `MilCmdRotateTransform3D` | 48 | |
| 0x6b | `MilCmdMatrixTransform3D` | 72 | |

`MeshGeometry3D`(0x62) 的尾部四段顺序与元素宽度，来自
`Media3D/Generated/MeshGeometry3D.cs:230-283` 的实测，不是推测：

```
Positions          12 × N   MilPoint3F
Normals            12 × N   MilPoint3F
TextureCoordinates 16 × N   Point(2×double)
TriangleIndices     4 × N   Int32
```

#### 0x29–0x30（8 条，本轮完成）—— 上一轮误分为 B，本轮纠正

上一轮把这 8 条判成 B，理由是需要 `Resources/` 的 `Viewport3DVisual`/`Visual3D` 节点模型。
**这个理由不成立**：0x57–0x6b 面对的是完全相同的处境（工厂对 3D 类型一律返回占位
`MilOpaqueResource`），既然那边用 `Commands/MilResource3D.cs` 的弱键附加表解掉了，
这边就该用同一把尺子量。载荷同样全是 POD：

| 命令字 | 命令名 | 固定长度 | 载荷（上游 `wgx_commands.cs` 实测） |
|---|---|---|---|
| 0x29 | `MilCmdViewport3DVisualSetCamera` | 12 | `hCamera`(4) |
| 0x2a | `MilCmdViewport3DVisualSetViewport` | 40 | `Rect Viewport`(32，4×double) |
| 0x2b | `MilCmdViewport3DVisualSet3DChild` | 12 | `hChild`(4) |
| 0x2c | `MilCmdVisual3DSetContent` | 12 | `hContent`(4) |
| 0x2d | `MilCmdVisual3DSetTransform` | 12 | `hTransform`(4) |
| 0x2e | `MilCmdVisual3DRemoveAllChildren` | 8 | 无 |
| 0x2f | `MilCmdVisual3DRemoveChild` | 12 | `hChild`(4) |
| 0x30 | `MilCmdVisual3DInsertChildAt` | 16 | `hChild`(4) + `UInt32 index`(4) |

状态落在 `Commands/MilResource3D.cs` 的 `MilViewport3DVisual` / `MilVisual3D` 两个模型上，
挂在**同一张** `MilResource3DTable` 弱键附加表里，仍不改 `Resources/` 一行。
`Visual3D` 的子节点列表是真的在增删（可回读断言），不是「返回 S_OK 但啥也没干」。

**⚠️ 边界（必须说清楚）**：这 29 条做到的是「**字段 100% 解码 + 状态落地**」，
**不做 3D 光栅化**。M1 没有 3D 场景图/渲染后端，解码结果目前无人消费。

### B 类 · 1 条（本次不做，登记前提）

| 命令字 | 命令名 | 缺什么前提 |
|---|---|---|
| 0x17 | `MilCmdMediaPlayer` | 上游无结构体（独立封送）；需播放器子系统（handoff §5 划归 M2） |

---

#### 0.1 位图源 0x0c / 0x0d（本轮实现，已从 B 类移出）

**实现**：`Commands/MilBitmapSource.cs`；结构体在 `Commands/MilCommandStructs.cs`；
解码分支在 `Commands/MilCommandDispatcher.cs`；渲染侧经
`MilBitmapSourceTable.AttachTo(provider)` 挂到 `Rendering/MilResourceProvider.BitmapResolver`
钩子上（`Rendering/` 一行未改）。

**偏移（与上游逐字节核对过，不是推测）**

| 命令字 | 结构 | 布局 | 长度 | 权威源 |
|---|---|---|---|---|
| 0x0c | `MILCMD_BITMAP_SOURCE` | `Type`@0(4) + `Handle`@4(4) + **8 字节列**@8 | 16 | C++ 头 `WpfGfx/include/Generated/wgx_commands.h:86` |
| 0x0d | `MILCMD_BITMAP_INVALIDATE` | `Type`@0(4) + `Handle`@4(4) + `BOOL`@8(4) + `RECT`@12(16) | 28 | C# 版 `Common/Graphics/Generated/wgx_commands.cs:62` |

0x0c 的**上游 C# 生成版里根本没有这个结构**（`verify-cmd-layout.py` 比对不到），
它的 16 字节只能照 C++ 头抄：`HMIL_RESOURCE` 就是 `UINT32`
（`WpfGfx/include/processed/wgx_core_types.h:60`），指针 8 字节自然对齐到偏移 8。
因此 `CommandLayoutTests` 里那条 `Marshal.SizeOf == FixedSize` 是它**唯一**的机械护栏，
`MilBitmapSourceTests` §A 又把三个 `FieldOffset` 单独钉了一遍。

**0x0c 的第 3 列在 Linux 侧是什么（必须说清）**

上游那 8 字节是 `IWICBitmapSource*`，靠「发送前 `AddRef` → 传输 → 从端接手引用」
的协议在**同一进程内**传递（`WpfGfx/core/uce/apifunc.cpp:731` 的注释）。
Linux 上没有 WIC，且本实现的命令流是纯字节流，进程地址在流里毫无意义。
所以这里**保留 8 字节列宽不变、只改它的解释**：改作**位图令牌**，
即进程内 `SKBitmap` 登记表的一个键。两边的引用协议一一对应：

| 上游（COM 引用） | 本实现（令牌） |
|---|---|
| `AddRef()` | `MilBitmapSourceTable.Register(bitmap)` |
| 随命令传输（引用保活） | 令牌在字节流里传输（8 字节，同宽） |
| 从端 `TryTake` 接手引用 | `ProcessSource` 里 `TryTake`（取出并注销） |
| `ReplaceInterface` 时释放旧的 | `Replace` 时 `Dispose` 旧的 |
| 失败分支 `ReleaseInterface` | `Discard(token)` |

令牌 0 恒为非法值，对应上游 `pIBitmap == NULL`。
**已知边界**：令牌只在**本进程内**有效，字节流落盘或跨进程重放后必然失效
（表现是 0x0c 返 `E_HANDLE`）。这与上游指针的局限一致——上游的指针同样不能跨进程。

**HRESULT 保真（本轮纠正了前一个 agent 的一处错）**：令牌无效时返回 **`E_HANDLE`**，
不是 `E_INVALIDARG`。本层是**接收侧**（`CMilSlaveBitmap::ProcessSource`），
上游的空对象校验是 `IFCNULL(...)`，而 `IFCNULL` 展开为
`CHECKPTRHRGOTO(Cleanup, obj, E_HANDLE)`（`WpfGfx/shared/util/UtilLib/instrumentationapi.h:915`）。
`E_INVALIDARG` 属于**发送侧** `MilResource_SendCommandBitmapSource` 的
`CHECKPTRARG(pIBitmapSource)`（`apifunc.cpp:728`），两边不是同一层。

**未做的事（不掩饰）**：`MilResource_SendCommandBitmapSource` 这个**导出函数**
仍是 `E_NOTIMPL`（见 §2）——它在 `Interop/exports.cs`，签名的 `_In_ IWICBitmapSource*`
要改成 Linux 侧等价物属契约变更，须主控协商。也就是说：命令**收得下、解得出、
画得出来**，但还没有一条托管的"发送"入口去造它。

### C 类 · 6 条（永久划掉）

| 命令字 | 命令名 | 依据 |
|---|---|---|
| 0x0a | `MilCmdD3DImage` | 载荷是 `UInt64 pInteropDeviceBitmap` + `UInt64 pSoftwareBitmap`，即 `IDirect3DSurface9` + `IWICBitmapSource` 的 COM 指针被塞进 8 字节整数 |
| 0x0b | `MilCmdD3DImagePresent` | `UInt64 hEvent` 是 Windows 跨进程同步事件句柄 |
| 0x6c | `MilCmdPixelShader` | HLSL 字节码（变长尾 `PixelShaderBytecodeSize`），需 D3D 编译与执行环境 |
| 0x70 | `MilCmdShaderEffect` | 同 0x6c，且需 `ID3DXEffect` 参数封送 |
| 0x3b | `MilCmdDoubleBufferedBitmap` | `UInt64 SwDoubleBufferedBitmap` 是指向原生 C++ `CSwDoubleBufferedBitmap` 的指针，Linux 无对应对象 |
| 0x3c | `MilCmdDoubleBufferedBitmapCopyForward` | `UInt64 CopyCompletedEvent` 是 Windows 事件句柄 |

> 0x3b / 0x3c **上一轮被判成 B（"需先有双缓冲位图子系统"），本轮改判 C**：
> 看了上游结构体后发现卡点不是"子系统还没建"，而是**载荷本身就是不可移植的
> Windows 句柄/原生对象指针**——即使双缓冲位图子系统建好了，这两个 `UInt64`
> 也解释不出任何 Linux 语义。这与 0x0a/0x0b 是同一类问题。
>
> 0x0a/0x0b/0x6c/0x70 依据 handoff §2 决策 4：M1 只做 Skia CPU 软件渲染。
> 将来若要支持，路径是 Shader → Skia `SKRuntimeEffect`，不是移植 D3D。

---

## 1. 顶层命令：7 / 118 返回 E_NOTIMPL

> **2026-09-04 更新**：38 条中的 31 条已实现 —— 0x57–0x6b 整段 3D 资源命令（21 条）
> + 0x29–0x30 整段 3D 视觉树命令（8 条）+ 本轮 0x0c/0x0d 位图源（2 条）。
> 0x0c 的 COM 指针列重定义为位图令牌，依据见 `## 0` 的 §0.1。
>
> **2026-09-03**：38 条中的 29 条已实现（21 条 3D 资源 + 8 条 3D 视觉树）。
>
> **2026-09-02**：上一轮先做了 0x57–0x6b 的 21 条。

总数核对：**7（未实现）+ 110（已实现）+ 1（`MilCmdInvalid` 哨兵）= 118**。
剩余 7 条 = 6（C 类）+ 1（B 类 `MilCmdMediaPlayer`）。
`MilCommandLayout.NotImplementedCommands` 与这个集合由
`CommandCoverageTests` 双向锁死。

### 1.1 D3D / 硬件加速（4 条 · C 类，永久划掉）

`handoff.md` 决策 4：M1 只做软件渲染（Skia CPU），放弃 D3D 硬件加速。

| 命令字 | 命令名 | 未实现原因 |
|---|---|---|
| 0x0a | `MilCmdD3DImage` | 依赖 IDirect3DSurface9 / D3DImage 互操作，Linux 无对应对象 |
| 0x0b | `MilCmdD3DImagePresent` | 同上，且依赖 `hEvent` 跨进程同步句柄 |
| 0x6c | `MilCmdPixelShader` | HLSL 着色器字节码，需 D3D 编译与执行环境 |
| 0x70 | `MilCmdShaderEffect` | 同 0x6c，且需 `ID3DXEffect` 参数封送 |

> 连带影响：`MilResource_SendCommandMedia` 之外的 D3D 相关导出也不可用。
> 后续若要支持，路径是 Shader → Skia `SKRuntimeEffect`，不是移植 D3D。

### 1.2 位图源（0x0c / 0x0d · **本轮 2 条已实现**，本表只剩媒体）

0x0c / 0x0d 已于 2026-09-04 实现并从 `NotImplementedCommands` 移除：
结构体进 `Commands/MilCommandStructs.cs`、解码分支进 `MilCommandDispatcher.cs`、
状态落进 `Commands/MilBitmapSource.cs`、渲染侧挂到 `BitmapResolver` 钩子。
偏移核对、COM 指针列的 Linux 语义重定义、以及纠正的一处 HRESULT 错误，
全部记在 `## 0` 的 §0.1。

**像素级证据**（`MilBitmapSourceTests.离屏渲染把位图画进目标矩形`）：
真实的 0x0c 命令字节 → 绑定位图 → 离屏渲染 64×64，目标矩形 `(16,16,48,48)`，
断言 `(32,32)`、`(17,17)`、`(47,47)` 三点为位图色（红），
`(4,4)`、`(60,60)`、`(32,4)` 三点仍为背景白，且 `Diagnostics.NotDrawn` 为空。
配套的反向用例 `没挂位图解析器时图像指令被记为未画出` 证明红像素只能来自位图。

| 命令字 | 命令名 | 未实现原因 |
|---|---|---|
| 0x17 | `MilCmdMediaPlayer` | 多媒体播放，M1 不做（见 `handoff.md` §5 M2） |

> 遗留：导出函数 `MilResource_SendCommandBitmapSource` 仍是 `E_NOTIMPL`（见 §2）——
> 那属于契约变更，须主控协商，不在本轮范围内。

### 1.3 Windows 句柄 / 原生对象指针（2 条 · C 类，永久划掉）

上一轮曾在 B 类（"需先有双缓冲位图子系统"）。查过上游结构体后改判：**卡点不是
子系统没建，而是载荷本身就是不可移植的 Windows 句柄/原生对象指针**——即使子系统
建好了，这两个 `UInt64` 也解释不出 Linux 语义。

| 命令字 | 命令名 | 上游载荷 |
|---|---|---|
| 0x3b | `MilCmdDoubleBufferedBitmap` | `UInt64 SwDoubleBufferedBitmap`（指向原生 C++ `CSwDoubleBufferedBitmap` 的指针）+ `BOOL UseBackBuffer` |
| 0x3c | `MilCmdDoubleBufferedBitmapCopyForward` | `UInt64 CopyCompletedEvent`（Windows 事件句柄） |

> 与 1.1 的 0x0a / 0x0b 是同一类问题：整数里装的是 Windows 对象身份，
> 不是可解释的数据。Linux 侧若要支持，得重新设计载荷语义，不是解码器能补的。

### 1.4 3D 视觉树（0x29–0x30 整段 · **8 条本轮实现**，本表清空）

载荷全是 POD，与 0x57–0x6b 同构，本轮按同一把尺子判成 A 类并实现。
上一轮误判为 B 的理由与纠正过程见 `## 0` 的 "0x29–0x30（8 条，本轮完成）" 小节。

### 1.5 3D 资源（0x57–0x6b 整段 · **21 条上一轮实现**，本表清空）

这一段整体是纯 POD 属性命令（见 `## 0. 本次分类结果` 的 A 类判据），
已于 2026-09-02 全部实现：结构体进 `Commands/MilCommandStructs.cs`、
解码分支进 `MilCommandDispatcher.cs`、状态落进 `Commands/MilResource3D.cs`、
并已从 `MilCommandLayout.NotImplementedCommands` 移除。

**未做的事（不掩饰）**：M1 无 3D 光栅化后端，解码结果目前没有消费者。
做到的是"解码 + 落地"，不是"渲染"。

---

## 2. 导出函数：29 个返回 E_NOTIMPL

> **2026-09-10（M7a）更新**：本节由 3 条扩到 **29 条**。
> M7a 的任务是从上游抓出全部 `DllImport(DllImport.MilCore)` 导出名并补齐缺口：
> 托管侧共需 **108 个导出名**（110 条属性去重后），M7a 之前已实现 14 个，
> **本轮补齐 94 个**——其中 **48 个真实现、9 个身份映射、11 个纯状态/同步、
> 26 个 `E_NOTIMPL`**。完整清单与实现深度固化在
> `src/WpfGfx.Linux/Interop/MilNative.Exports.cs` 的 `MilNative.ExportManifest`。
>
> 📌 **数字更正**：`docs/U2-PresentationCore-scan.md` §3.4 原写「104 条属性 / 102 个导出名 /
> 缺口 95」，复核后确认 Common/Graphics 是 **47** 条属性（原报告漏算 6 条），
> 正确数字是 **110 条属性 / 108 个导出名 / 缺口 94**。该报告与 `handoff.md` 由主控统一更正，
> 本文件只更正与 §2 直接相关的口径。

### 2.0 机械校验入口（本节与代码的对应关系）

| 入口 | 作用 |
|---|---|
| `MilNative.ExportManifest` | 108 个导出名 → 实现深度（`Real` / `Identity` / `State` / `NotImpl`），是本节 29 条的**唯一权威来源** |
| `MilNative.NotImplExportNames` | 深度为 `NotImpl` 的导出名（§2.1–§2.3 的并集，字典序） |
| `MilNative.MissingExports()` | 清单里没有同名 public static 方法的导出名，**应当恒为空** |
| `MilExportTests.导出清单包含全部108个MilCore导出名` | `ExportManifest.Count == 108` |
| `MilExportTests.清单里每个导出名都有同名public静态方法` | `MissingExports()` 为空 |
| `MilExportTests.既定实现的导出数量与分组一致` | 59 Real / 9 Identity / 11 State / 29 NotImpl = 108 |
| `MilExportTests.未实现清单包含21个媒体导出与4个D3D互操作导出` | §2.1 / §2.2 的条数与成员 |

**覆盖度自检**：94 个 M7a 新增导出名**全部**被 `tests/.../Commands.Tests/MilExportTests.cs`
引用（脚本核对结果 `NOT referenced by tests: []`）——每个新导出至少一条用例，
不存在"补了名字没测"的条目。

> ⚠️ 本节与 §1 是**两条不重叠的轴**，不要互相推导：
> 顶层命令走 `MilCommandLayout.NotImplementedCommands`（7 条，命令字维度），
> 导出函数走 `MilNative.NotImplExportNames`（29 条，`wpfgfx_cor3.dll` 导出名维度）。
> 同一个功能可能在两条轴上各登记一次（例如媒体：命令 0x17 + 导出 `MILMedia*`）。

### 2.1 媒体（22 条 = `MILMedia*` 21 + 工厂入口 1 · handoff U3 口径：暂缓）

上游 `MILMedia*` 背后是 WMP / MediaFoundation。Linux 侧既没有解码器，
也没有音视频呈现路径，因此整条面统一返回 `E_NOTIMPL`；
`MILFactoryCreateMediaPlayer` 是这条链的入口，随之一并延后。

| 函数 | 原因 | 恢复条件 |
|---|---|---|
| `MILMediaOpen` / `MILMediaClose` / `MILMediaStop` | 无解码器 | 接入 GStreamer/FFmpeg 之类的解码后端 |
| `MILMediaSetPosition` / `MILMediaGetPosition` / `MILMediaGetMediaLength` | 无播放时钟与时长探测 | 同上 + 播放状态机 |
| `MILMediaSetVolume` / `MILMediaSetBalance` / `MILMediaSetRate` | 无音频输出、无变速能力 | 接入音频后端（PipeWire/ALSA） |
| `MILMediaSetIsScrubbingEnabled` / `MILMediaCanPause` | 无播放状态机 | 同 `MILMediaOpen` |
| `MILMediaIsBuffering` / `MILMediaGetDownloadProgress` / `MILMediaGetBufferingProgress` | 无网络缓冲模型 | 同 `MILMediaOpen` |
| `MILMediaHasVideo` / `MILMediaHasAudio` / `MILMediaGetNaturalWidth` / `MILMediaGetNaturalHeight` | 无媒体探测 | 同 `MILMediaOpen` |
| `MILMediaNeedUIFrameUpdate` | 无视频帧回调 | 同 `MILMediaOpen` |
| `MILMediaShutdown` / `MILMediaProcessExitHandler` | 无媒体子系统可关 | 随媒体子系统一并落地 |
| `MILFactoryCreateMediaPlayer` | 上一条链的入口，随媒体一并延后 | 同 `MILMediaOpen` |

> **出参写安全默认值**（`false` / `0` / `0.0`）：上游在失败路径上不保证写出参，
> 而托管侧有直接读它们的分支（例如 `IsBuffering` 的 `ref bool`）。
> 写默认值是**失败路径的语义**，不是"假装成功"。
>
> **为什么不返回 `S_OK`**：`MediaPlayer` 的托管侧对 `S_OK` 有反应链——
> 拿到成功码后它会认为媒体已打开并开始查询时长/尺寸/缓冲进度，于是走进一条
> 永远拿不到数据的状态机（`MediaOpened` 永不触发，UI 上是个黑框）。
> 明确失败至少让异常出现在 `Open()` 调用点，可定位。

### 2.2 D3D 互操作（4 条 · Linux 无对应子系统）

| 函数 | 原因 |
|---|---|
| `InteropDeviceBitmap_Create` | 无 D3D11、无共享纹理句柄、无 DWM。硬返回 `S_OK` 会让 `D3DImage` 进入"以为有纹理"的状态，之后每一帧都画错——比明确失败更难查 |
| `InteropDeviceBitmap_Detach` | 从未创建过这类对象，没有资源可解绑（`void` 导出，幂等空操作） |
| `InteropDeviceBitmap_AddDirtyRect` | 同上（无源对象可标脏） |
| `InteropDeviceBitmap_GetAsSoftwareBitmap` | 同上（无源对象可降级成软件位图） |

> 参数校验**先于** `E_NOTIMPL`：空 D3D 资源 / 非法 DPI 返回 `E_INVALIDARG`。
> 恢复条件：handoff 决策 4 明确 M1/M2 只做 Skia CPU 软件渲染；
> 若要支持，路径是重新设计载荷语义（纹理 → `SKImage` 共享），不是移植 D3D。

### 2.3 M1 存量（3 条 · 原条目保留）

| 函数 | 原因 |
|---|---|
| `MilResource_SendCommandMedia` | 媒体命令（`SafeMediaHandle`），M1 不接 `MediaPlayer`（0x17） |
| `MilResource_SendCommandBitmapSource` | **`Interop/exports.cs` 属契约层，本轮不动**。命令 0x0c 本身已能收/解/渲染，但这个托管发送入口的签名是 `_In_ IWICBitmapSource*`，改成 Linux 侧等价物属契约变更，须主控协商。在此之前，0x0c 命令只能由非托管的字节流喂进来 |
| `MilChannel_SetNotificationWindow` | 参数是 HWND + `WindowMessage`；Linux 上没有 HWND 消息循环。呈现通知改由 `Rendering/` 侧直接驱动 |

### 2.4 语义不完整（**不是** `E_NOTIMPL`，但同样登记）

以下 4 条**返回成功码**，所以不在上面的台账里；但它们的语义只落到一半，
凡是依赖这些行为的路径都不能按"已完成"理解。

| 项 | 现状 | 缺什么 | 恢复条件 |
|---|---|---|---|
| `MilComposition_WaitForNextMessage` 的 `pHandles` 参数 | 参数校验完整（`nCount>0 && pHandles==NULL`、`nCount>63` → `E_INVALIDARG`），消息就绪 → `waitReturn=0`，否则按 `waitTimeout` 轮询 → `WAIT_TIMEOUT(258)`；**句柄数组只校验、不参与等待** | Linux 侧没有内核事件对象，句柄无法被 `WaitForMultipleObjects` 语义等待 | eventfd/pipe + X11 事件源接进等待循环 |
| ~~`MilVisualTarget_AttachToHwnd` / `DetachFromHwnd` 只做身份映射~~ → **✅ 已闭环（M7c，2026-09-10/11）** | 身份映射之外**真的接窗了**：`Attach` → `MilPresentation.TryBind`（`MilNative.Window.cs:146`）→ `X11PresentationTarget.WrapExisting(Display, hwnd)`（`MilPresentation.cs:405`）；`Detach` → `TryUnbind`（`:162`）。出图路由也已通：`WgxConnection_SameThreadPresent` → `PresentChannel`（`MilPresentation.cs:625`）→ `TryGetTarget(hwnd)` → `X11PresentationTarget.Present`。**端到端证据**：M2 验收 —— 真 WPF 窗口 `0x200005 "HelloWpf on Linux"` 667×417 `IsViewable`、`docs/m7c-accept-zero-probe.png`（56,055 B）经视觉核验画出文字/矩形/渐变椭圆/旋转三角/径向渐变/第二行文字，`未画种类 0`。反向派发也已通：**指针进窗口会走到 `HwndMouseInputProvider` → `InputManager.ProcessInput`**（这正是下面登记的那个崩溃的触发链，反过来说明了 XEvent → 消息的路是通的）。绑定失败**刻意不改写本函数 HRESULT**（"登记可以宽容，出图必须诚实"，失败原因经 `MilPresentation` 记入诊断并在 Present 时变成失败码） | — | — |
| `MilContent_AttachToHwnd` / `MilContent_DetachFromHwnd` | **仍只做登记**（`MilNative.Window.cs:170/177`，恒 `S_OK`）。这是**有意的平台等价**而非缺口：上游这两条是 `DwmAttachMilContent`，Linux 无 DWM，语义确实只是"内容已挂到该窗口"的幂等提示 | 无（若将来接合成器，这里才需要真动作） | 不适用 |
| ⚠️ **本行此前写作"实现里没有一行 X11 调用"，该说法已过期并误导过一次** | 2026-09-11 主控据此判定"轨道 C 未做"，实际代码早已接线 —— **根因是只读了 `MilNative.Window.cs` 的文件头注释、没读函数体**。教训对**所有**读这份文档的人：**判断"某功能有没有做"必须读代码路径，注释与文档都会过期，而过期注释比没有注释更危险（它让人以为已经核实过）** | — | — |
| ~~`fSkipHollows`~~ → **✅ 已实现（2026-09-10 U1c 真机对拍）** | 此前"接受但不改变结果"的判断被真机否证：真机按图形标志过滤，实测 `(0,0,10,10)`。已按真机行为实现并加回归断言 | — | — |
| ~~`rTolerance` / `fRelative` 被忽略~~ → **✅ 该判断被真机否证（2026-09-10 U1c）** | 真机 `Widen` 的容差是**真用**的（实测 tol=0.001 → 1267 点、tol=10 → 19 点）。相关函数已按容差参与计算修正 | — | — |

> **U1c 真机对拍新增的 4 类登记（2026-09-10，详见 `docs/U1c-geometry-oracle.md`）**：
> ① **描边轮廓分解表示差异**（12 例）：真机 `Widen` 把描边环发成**一个带接缝的闭合轮廓**，我们用 Skia 发成外圈+内圈两个环——
> 区域相同、几何等价，但字节表示不同；**主控裁定：不修，登记为已知表示差异**（重写描边轮廓生成代价过高，下游填充结果一致）；
> ② **展平密度差异**：上游 `CBezierFlattener` 与我们递归细分策略不同（容差 0 时上游取 `extent*1e-12`，我们兜底 0.1）→ 点集不同但几何近似，**单开 milestone 处理（U14）**；
> ③ **TileBrush 0 宽/高加固**：真机除零产出 `INF/NaN` 矩阵，我们**刻意**当空画刷返回 → **主控确认保留加固**（把 NaN 传播进 Skia 更糟），登记为有意偏差；
> ④ 若干零散差异（端帽离散化 / 虚线段闭合表示 / Outline 图形分解 / 共边 Union 多一个共线顶点 / 弧长参数化差 0.58% / NaN 分数真机 S_OK 而我们 E_FAIL）已逐条记入 `U1c-geometry-oracle.md`，本轮不改。

> **上游自身的三个坑（U1c 实测记录，供后人排障）**：`MilUtility_Widen` **从不写 `outFillRule`**（哨兵 `0x5EED0001` 原样回吐，
> 托管侧因此读到栈垃圾）；`MilUtility_ArcToBezier` 在半径退化时会**拷贝未初始化栈内存**；
> `MilUtility_Combine` 的 SAL 注释 `__in_ecount_opt` 与 `IFCNULL` 实现矛盾（传 NULL 矩阵实际返回 `E_HANDLE`）。

> 另有两条"半实现"同样只做到身份映射，一并说明：
> `MILCreateStreamFromStreamDescriptor` 的**写路径是真的**（`MILIStreamWrite` 真写进内存流），
> 但 `Read`/`Seek`/`Stat`/`CopyTo` 等 13 个委托没有 native 侧消费者，未接；
> `MilCreateReversePInvokeWrapper` 只做登记 + 引用计数，没有生成真正的 native 可调用 thunk
> （本工程"原生层"就是托管，两侧函数指针同值，暂无需要；将来若真有 C++ 模块回调托管，这里要重做）。

### 2.5 接线时的类型映射注意事项（M7a）

把上游的 `[DllImport(DllImport.MilCore)]` 声明改成对本程序集同名方法的调用时，
**签名不是逐字相同**，差异全部来自三条硬约束，逐条列在这里以免接线时踩坑：

| 上游类型 | 本工程类型 | 原因 / 转换方式 |
|---|---|---|
| `SafeMILHandle` / `SafeMediaHandle` / `BitmapSourceSafeMILHandle` | `IntPtr` | 沿 `MilNative.cs` 既有契约（M1 起就如此）；句柄由 `MilHandleSource` 单调下发，是**进程内逻辑句柄**，不是内核对象，不能跨进程、不能 `CloseHandle`，注销后该值**永不复用**（陈旧句柄只会拿到 `E_HANDLE`） |
| `WindowMessage` | `uint` | 同上（M1 不投递窗口消息） |
| `MilMatrix3x2D*` | `double*` | C# **不允许 public 方法签名里出现 internal 类型（CS0051，`InternalsVisibleTo` 也无效，已实测）**，而本工程既有的 `MilMatrix3x2D` 是 internal。指针指向 **6 个连续 double**：`S_11 S_12 S_21 S_22 DX DY`，布局与上游逐字节一致，调用方 `(double*)&matrix` 即可 |
| `System.Windows.Point` / `Size` / `Rect` | `MilPointD` / `MilSizeD` / `MilPointAndSizeD` | 同为 public 镜像类型（布局逐字段一致）；`MilPointAndSizeD` 是 `X,Y,Width,Height`（= `System.Windows.Rect`）。注意与 `MilRectD`（`Left,Top,Right,Bottom`，对应上游 `MilRectD`）**语义不同**，别混用 |
| `D3DMATRIX` / `MIL_PEN_DATA` / `MILRect3D` / `MilRectF` / `Int32Rect` | 同名 public 类型（`Int32Rect` → `MilInt32Rect`） | 逐字段复制上游布局，`Marshal.SizeOf` 有测试钉住 |
| `PathGeometry.AddFigureToListDelegate` | `MilAddFigureCallback` | 委托形状逐参数一致（`bool, bool, MilPoint2F*, uint, byte*, uint`），适配层转一次即可 |
| `System.Windows.Media.StreamDescriptor` / `EventProxyDescriptor`（PresentationCore 内部类型） | `IntPtr` | 指向该结构体的指针；`MILCreateEventProxy` / `MILCreateStreamFromStreamDescriptor` 只登记地址，不解释内容 |
| `MilUtility_CopyPixelBuffer` 的 `PreserveSig = false` | 返回 `int` HRESULT | 上游用 `PreserveSig=false` 声明（失败抛异常），适配层**必须把 HRESULT 转成异常**，否则调用点会静默继续 |
| `MilGlyphRun_GetGlyphOutline` 的 `out byte* pPathGeometryData` | 同样是 `out byte*` | 内存由 `Marshal.AllocHGlobal` 分配，**必须**配 `MilGlyphRun_ReleasePathGeometryData` 归还（上游 `GlyphTypeface.cs:1263/1283` 正是这样的配对）；重复释放返回 `E_INVALIDARG` 而不是 UB |

**需要宿主显式登记的入口**（Linux 上这些"指针"没有本机含义，必须由上层映射）：

| 入口 | 用途 |
|---|---|
| `MilFontFaceTable.Register(SKTypeface)` / `DefaultTypeface` | DWrite 字体面指针 → `SKTypeface`（`MilGlyphRun_GetGlyphOutline`）。未登记的非 0 句柄退回 `DefaultTypeface`，两者都没有 → `E_HANDLE`（不猜字体） |
| `MilHwndRegistry` | HWND → 窗口身份（可由 `X11PresentationTarget.NativeHandle` 作为 HWND 值） |
| `MilPixelBufferTable` / `MilColorContextTable` / `MilRenderTimeTargetTable` / `MilConnectionTable` | 位图缓冲（IWICBitmap 等价物）、ICC 色彩上下文、渲染时目标（`*_AtRenderTime` 三件套）、连接对象 |

> 测试侧另有 `MilNative.ResetProcessStateForTests()`：一次性清空全部进程内句柄表与开关，
> 供测试建立干净基线（**不清** `MilChannelRegistry`——那是跨测试类共享的全局量）。
>
> 分组归属与"哪 48 条是真实现"的完整表格见 M7a 报告；
> 代码内每组的实现深度注释在各 `Interop/MilNative.*.cs` 的文件头。

---

### 2.6 ⚠️ **已过期（2026-09-11 复核）**：`build/fonts-ui/UI-NoLayout.ttf` **不再是默认 UI 字体**，它只是**诊断档位**用的目录

> **原结论（M2 时期，保留作历史）**：HelloWpf 运行期的**默认 UI 字体**采用 `build/fonts-ui/UI-NoLayout.ttf`
> （= `NotoSans-Regular` 剥离 `GSUB`/`GPOS` 的派生件，由 `build/gen-ui-font.py` 生成，sha256 `b008d486…c3250c55`），
> 因此默认 UI 字体下**没有 kerning、没有连字（liga）、没有 locl 本地化替换**。
>
> **2026-09-11 逐条对码复核（T2b 只读审计 + 主控落笔）**：文件仍在（332,736 B），但**引用面只在测试/探针档位与一处注释**：
> ```
> build/MilBridge/tools/t1b-live-window.sh:8,72   （诊断档 HLWPF_UI_FONT=…/UI-NoLayout.ttf）
> build/MilBridge/tools/t1d-probe.sh:12,70,87      （档④ fonts-ui；注释明写"结构性无解：该集合 0 个 CJK 码点"）
> build/MilBridge/tools/t1c-census.sh:16           （env 档：复刻 M2 验收件的配置）
> src/WpfGfx.Linux/Interop/MilPresentation.cs:388-389（注释，讲的是"档②只设 WPF_LINUX_TEXT_FONT_DIR=build/fonts-ui"这个测试档）
> ```
> ⇒ **没有任何生产路径把它当默认 UI 字体**。**真默认族**走 SPI 同源族 + `Factory.Linux.cs` 的 `ResolveSystemFontDirectories()`（见 §2.6 下文与 `docs/ARCHITECTURE.md` #16）。
> **⇒ 该节现在的正确读法**：`fonts-ui` 是**诊断档位的历史成因与局限**（**0 个 CJK 码点 ⇒ 结构性无法覆盖中文**），**不是**运行期降级。
> **⚠️ 仍未证的一格（如实登记）**：审计**没有**逐行核 `ResolveSystemFontDirectories`/`Win32UiFont` 那条链 ⇒ "**默认族现在具体解析成什么**"要么读那段代码、要么取一次运行期读数才算证完。

**（以下为原始记录，解释"当年为什么要剥离"）**

**降级内容（历史）**：`build/fonts-ui/UI-NoLayout.ttf`（= `NotoSans-Regular` 剥离 `GSUB`/`GPOS` 的派生件，由 `build/gen-ui-font.py` 生成，sha256 `b008d486…c3250c55`）。在该档位下**没有 kerning、没有连字（liga）、没有 locl 本地化替换**。

**为什么必须这样**：WPF 的 `Typeface.CheckFastPathNominalGlyphs`
（`PresentationCore/System/Windows/Media/Typeface.cs:520-562`）在文本全为 fast-text 字符时，
读 `FontFaceLayoutInfo.TypographyAvailabilities`（`FontFaceLayoutInfo.cs:387-545`）：
只要字体在 fast-text 字形范围上带有 `{ccmp,rlig,liga,clig,calt,kern,mark,mkmk}` 之一（或主流语言的 `locl`），
就**拒绝名义字形快路径**、回落到 LineServices。而 Linux 侧 LineServices（110 条 `Lo*/Fs*/Nl*`）未实现
⇒ 文本测量/绘制会异常退出。**走真实 PC 代码路径实测**：未剥离 Noto Sans = **21**（含 `FastTextTypographyAvailable(4)`）⇒ 拒；
派生件 = **0** ⇒ 放行；DejaVu Sans = **23**（三方一致）⇒ 拒。

**这不是「绕过闸门」**：fast path 的语义本来就是**名义字形** —— 不做 kerning、不做连字、不做 locl 替换。
剥离 GSUB/GPOS 之后字体**确实**不再带这些特性（掩码 0 是**测出来的事实**，不是把算法改成 0 伪造的），
渲染结果与快路径一致；而字形 id、轮廓、步进、`cmap` 码点映射与全部度量**逐项不变**
（`build/DirectWrite.Linux/Tests/TypographyGateTests.cs` 有断言：3884 字形步进/lsb、全部 65536 个 BMP 码点、Skia 加载一致性）。

**影响面与边界**：
- 只影响**默认 UI 字体**；应用显式指定的其他字体不受影响。
- 其他真实字体（如 DejaVu Sans，实测掩码 23）**仍然会**触发闸门 2 ⇒ 回落 LineServices ⇒ 失败。
- ⚠️ 派生件**刻意放在独立目录** `build/fonts-ui/`（不放 `build/fonts/`）：实测同族同字重的派生件会**遮蔽基准件**
  （`FontSet` 按 `(族名,字重,斜体)` 索引、后加载者覆盖先加载者）⇒ 会让 6 条既有断言（基准字体解析/集合计数）变红。

> ### ⚠️ 更正（2026-09-10 晚，主控）："当前只有默认 UI 字体这条路能出字"**是推断，且已被实测推翻**
>
> 本文原先在这里写过一句"**也就是说：当前只有默认 UI 字体这条路能出字**"。它依赖一个**未经实测的假设**：
> 闸门 2 是上屏前的最后一道门。**实际不是** —— 还有**第三道**，而且它不是降级、是 **bug**：
> Win32 shim 的 `GetDeviceCaps(hdc, LOGPIXELSX/LOGPIXELSY)` **实测返回 0**
> （主控用 ctypes 直调 `libwpfwin32.so` 量到；对照 `GetDpiForSystem()` 返回 96 是对的），
> 经 `Visual.cs:4679 GetDpi() → UIElement.cs:1128 EnsureDpiScale() → DpiScale(0,0)` 传成 `PixelsPerDip = 0`，
> 使 `TextFormatterImp.cs:646 RoundDipForDisplayMode(v, 0) = Math.Round(0)/0 = NaN`
> ⇒ `Typeface.cs:463` 主循环条件恒 false ⇒ `SimpleTextLine.cs:1647 CreateSimpleTextRun` 返回 null ⇒ 回落 LineServices。
>
> **实测事实**：掩码 0（闸门 2 确已放行）之后，**派生字体同样没能出字**
> （M7b 实测 `charFastTextCheck=0x10`、缺字形 0/18、`TypographyAvailabilities=0`，仍然进了 LineServices）。
>
> **登记口径（改了什么、没改什么）**：本节的**降级部分**——派生字体、掩码 0、剥离 GSUB/GPOS 是**测出来的事实**而非伪造——
> **依然成立、一字未改**。被更正的只是"它已经足以让文字上屏"这一**因果声明**。
> 等 DPI 修好、窗口真的出字之后，需要**重新实测**"哪些字体能出字"再回填本句；
> **在此之前，本节不宣称任何字体可出字。**

**正解（独立里程碑，**分两步** —— T1 · 2026-09-10 路线决策，主控核准）**：

**第 1 步 · 把降级通用化** —— ✅ **已完成（T1 · M7c5，2026-09-10；主控独立复验）**。
运行期剥离落在 `build/DirectWrite.Linux/Provider/{FontLayoutStripping.cs,FontTableStripper.cs}`，开关 `WPF_LINUX_STRIP_LAYOUT`（**默认开**）+ 逐次旁路参数。
- **与 Python oracle 字节全等**（`332,736 B / 332,736 B`）；**唯一与"原始文件"的差异是 `head` 偏移 8..11 的 `checkSumAdjustment` 4 字节**（OpenType 规范强制重算，oracle 同样如此）。
- **闸门 2 真的过了，走真实 PC 代码路径**（`WiringSmoke` 调 PC 自己的 `FontFaceLayoutInfo`）：**Noto `MASK 21→0`、DejaVu `23→0`，`CheckFastPathNominalGlyphs` `False→True`**（两个语料位组合不同：21=`1|4|16`、23=`1|2|4|16`，所以两个都要测）。
- **零额外语义损失**：upem / glyphCount **3884** / **3884 个字形步进+lsb** / **全部 65536 个 BMP 码点** / Skia 加载与逐字形步进**全部一致**，**`GDEF` 剥后仍在**（只丢 `GSUB`/`GPOS`）。
- **受影响的既有断言恰好 3 条、全是"原始文件保真"类、一条都没放宽**：改成把装置语义显式化为"原始语料"（`stripLayout:false`），并**新增 2 条**把"确实跑在不剥模式"钉住；`TypographyGateTests`（8 条）一行未改。**21 与 0 现在分别在两条各自成立的断言里。**
- 回归：`DirectWrite.Linux.Tests` **94 → 115**（连跑 2 次一致），`run.sh strip` **21/21**。
- ⚠️ **默认开的产品论证**：关掉时 → 闸门 2 拒 → `FullTextLine` → `LoCreateContext` 等 **26 条原生符号缺失 → 崩**；开着时名义字形正常渲染。
  代价只有**元数据**（`FontCapabilities` 报"无特性"），而**当前没有任何消费者能使用那些特性**（本工程没有 shaper）。
- ⇒ **"只有默认 UI 字体能出字"这条产品级限制已解除**：任何字体都能过闸门 2。派生件 `build/fonts-ui/UI-NoLayout.ttf` 从此**只作 oracle 保留**（主控复验 `sha256 b008d486…` 未变），不再需要作为运行期字体。
  **⚠️ 但"端到端文字真的画到屏上"仍未验收** —— 见下方更正块（`MilDrawGlyphRun` 的渲染器尚未挂宿主）。

**第 2 步 · 真实 shaping + 行布局（目标态）**：用 **HarfBuzz 2.7.4**（系统 `libharfbuzz.so.0`，**395 个导出符号**，
自带 UCD 故不需要 ICU 做 Unicode 属性；**`DllImport` 必须写全名** —— 未装 dev 包，没有 `libharfbuzz.so` 这个无版本符号）
做 GSUB/GPOS，用 **ICU 70**（`libicuuc.so.70` 的 `ubrk_*_70`，UAX#14）做断行，
在**托管侧**实现 `MS.Internal.TextFormatting.TextLine` 契约（`FullTextLine` 有 33 个 `public override`），
从而**绕开整个 `PresentationNative_cor3.dll`**。shaping 侧**没有跨运行时问题**（HarfBuzz 是系统 .so，跑在 PC 进程里）；
轮廓侧跨 AOT 边界，已由 `MilFontFace_RegisterFromFile` + `MilGlyphRun_GetGlyphOutline` 打通（实测 13/13 字形取到真轮廓，共 9136 字节）。

> ⚠️ **不要再写"补齐 LineServices 的 110 条导出"** —— 那套 C++ **不在本仓库**，详见 §2.7。
> ⚠️ **shaping 与 LineServices 不互斥、不互相替代**：复杂路径的 shaping 是**托管回调**
> （`TextAnalyzer.GetGlyphs` @ `build/DirectWriteForwarder.Linux/ManagedSurface.cs:1139`、
> `GetGlyphPlacements` @ `:1150`，现为 PNSE），原生 LS 只是**回调它们**；
> 而 LS 引擎本身（26 条未实现）是**独立的**缺口。**只做 HarfBuzz 回调进不去，只补 LS 拿不到字形。**

> **⚠️ 关于"闸门 3"的更正**：本文一度把 `PixelsPerDip = 0`（Win32 shim 的 `GetDeviceCaps` 返回 0，已实测确认的真缺陷）
> 写成"闸门 3 就是它"。**该因果链已由主控撤回**：`RoundDip`/`IdealToReal`/`GetDesignGlyphMetrics` 都**只在 `TextFormattingMode.Display` 下**才用 ppd，
> 而默认是 `Ideal`（`TextOptions.cs:29`）⇒ ppd=0 不进入该判据。**闸门 3 的身份仍未定案**，
> 处置见 `handoff.md` 的「DPI 面缺陷」节（DPI 照修 + 在 `return null` 各出口打点定位）。

**登记口径**：本条目属「已明确降级 + 已验证的替代路径」，不是「静默失败」——
掩码值由 `WiringSmoke` 在真实 PC 代码路径上实测并留档（见 `build/DirectWrite.Linux/REPORT.md` §11.2）。

### 2.7 LineServices / PresentationNative 的真实缺口（T1 · 2026-09-10 实测；主控已独立复验关键项）

> **✅ 2026-09-13 第二次逐条 `nm` 复核（T2b，只读；**件已换代**，`27 / 1 / 26` 仍逐行成立）**：
> ```
> 件：src/WpfGfx.Linux.Native/bin/libwpfwin32.so
>     sha256 前 32 = e1691fd8440da926cb411a06cba23227 ｜ 269,616 B ｜ 导出 462 ｜ WpfLinuxWin32_* 19
> 命令：nm -D --defined-only <so> | awk '{print $3}' | sort -u   （**逐名比对**，见下方⚠️）
> 上游名单：upstream/…/MS/internal/TextFormatting/LineServices.cs 的 EntryPoint 名，共 27
> ⇒ 存在 = 1（`LoGetEscString`）｜ 缺失 = 26（22 个 `Lo*` + `CreateTextAnalysisSink` /
>   `CreateTextAnalysisSource` / `GetNumberSubstitutionList` / `GetScriptAnalysisList`）
> ```
> **M7b 本轮新增的 19 个 `WpfLinuxWin32_*` 导出与 LS 无关**（判据 `grep -cE '^WpfLinuxWin32_.*(Lo|Ls|LineServ)'` = **0**）⇒ **26 条缺口一条没补**，本节数字**不因本轮变化**。报告：`build/MilBridge/T2b-unimplemented-audit.md`。
> ⚠️ **取证命令要精确到"逐名比对"，不要用 `nm -D … | grep " Lo"`** —— 它会把 `LoadCursor` / `LoadImage` / `LoadLibrary` / `LocalFree` 这些**同前缀的 Win32 名字**一起捞进来（T2b 实测片段即证）。**"查法不对"会让结论看起来对或错**，这一族本工程已栽多次。

> **✅ 2026-09-11 逐条 `nm` 复核（T2b，只读；文档数字被确认准确）**：
> ```
> 上游名单：LineServices.cs 的 EntryPoint 总数 = 27   （与本文档一致）
> 目标件：src/WpfGfx.Linux.Native/bin/libwpfwin32.so（264,552 B），nm -D --defined-only = 458 个动态符号
> 逐条 comm：**存在 = 1**（LoGetEscString）｜**缺失 = 26**   （Lo/Fs/Nl* 前缀子集里缺 22 + 4 个不带前缀的）
> ```
> ⇒ **"缺 26 条"复核通过**（审计者原先标注"按文档复述、未复核"这一点**已撤回**）。
> **⚠️ 顺带更正本工程另一处口径（已生效）**：`libwpfwin32.so` 里 `LoCreateContext`/`LoCreateLine` 连**符号都没有**
> ⇒ 真走到 LS 是 **`EntryPointNotFoundException`（硬崩）**，**不是** `E_NOTIMPL`（见 `docs/ARCHITECTURE.md` #18）。
> 这与本节的"缺口"是同一件事的两种表述：**缺口 = 26 条符号不存在**。

**LS 的 P/Invoke 面只在一个文件里**：`PresentationCore/MS/internal/TextFormatting/LineServices.cs:1407-1618`，
**27 条** `[DllImport(DllImport.PresentationNative)]` → `PresentationNative_cor3.dll`（`Shared/RefAssemblyAttrs.cs:69`）。当前状态：
- `libwpfwin32.so` 已实现 **1** 条（`LoGetEscString`，`src/WpfGfx.Linux.Native/src/win32_classification.c:171`）
- Linux `.so`（`wpfgfx_cor3.so`）里 **0** 条
- **文本路径缺口 = 26 条**（`LoCreateContext`/`LoCreateLine`/`LoDisplayLine`/`LoEnumLine`/`LoQueryLinePointPcp`/
  `LoQueryLineCpPpoint`/`LoCreateBreaks`/`LoCreateParaBreakingSession`/`LoAcquirePenaltyModule`/
  `CreateTextAnalysisSink`/`GetScriptAnalysisList`/… 逐条见 `build/MilBridge/T1-report.md`）

**`PresentationNative` 全体**：128 个活名字 → 30 存在 / **97 缺失**（= 93 条文本布局引擎族 + 4 条 Win32 直通包装）。

⚠️ **工具口径「110」要更正**：110 = 94（LS/FS/NL 族）+ 4（Win32 包装）
+ 11（`Pts.cs` 里 `#if NEVER` 的**死声明**，工具不求值预处理）+ 1（`FindWindowExWrapper` 误报，Unicode 探测序）
− 1（`LoGetEscString` 已实现）。另注：`src/WpfGfx.Linux.Native/bin/exports.txt` 相对 `.so` **已过期**（缺 `LoGetEscString`），
重跑 `build-shim.sh --symbols` 前不要用它算缺口。

⚠️ **这些符号没有上游 C++ 实现（主控独立复验）**：`grep -rl` 五个代表符号
（`LoCreateLine`/`LoDisplayLine`/`LoCreateContext`/`FsGetBreakOpportunities`/`NlGetGlyphs`）
在 `WpfGfx/**/*.{cpp,h,hpp}` 里 → **各 0 个文件**；`WpfGfx/core/` 下**没有 `text`/`ls`/`pts`/`nl` 目录**
（只有 `api av common control dll fxjit geometry glyph hw meta regkeys resources sw targets uce`）；

🔴 **2026-09-11 更正「失败形态」（T1b 实测，主控收下）—— 这条比上面的计数更要紧**：
`nm -D src/WpfGfx.Linux.Native/bin/libwpfwin32.so` 里 **`LoAcquireBreakRecord` / `LoCreateLine` 连符号都不存在**
（整个 `.so` 的 LS 面只有 `LoGetEscString` 与 `LsDisableSpecialCharacterLigature`）。
⇒ 所以"**文本路径真的走到 LineServices**"时的现象**不是** `E_NOTIMPL`（那需要一个同名导出），
而是 **`EntryPointNotFoundException` —— 硬崩**。
**推论（写文档别写错）**：本项目先前几处"撞上 `E_NOTIMPL` 就说明走到 LS 了"的取证设计**是错的**——
`E_NOTIMPL` 只适用于**我们已导出并整流实现**的那批符号；LS 那 26 条**根本没导出**，撞上是崩不是返回码。
**正确的取证装置**（T1b 已改用，主控批准）：**`LD_PRELOAD` 拦 `dlsym`**，记录"PC 有没有按名字要过 `Lo*` 导出"——
**能问到名字**就证明它真的在选路时往 LS 走；**且该装置必须先自证不撒谎**（否则又是一个没牙的断言）。
`upstream/.../src/redist/` **整个目录不存在**（`Microsoft.Dotnet.Wpf.sln:247` 指向的
`redist/PresentationNative/PresentationNative.vcxproj` 因此无法构建）。
⇒ **这条不是"移植未做"，是"没有可移植的源"**。任何"补齐 LineServices"的估算都必须从这个前提出发：
它等于**在没有任何参考实现、没有任何 Windows 二进制可对拍的前提下，从零写一个行布局引擎**。

**反向方向同样空转**：`LineServices.cs:36-373` 的 28 个委托、`LineServicesCallbacks.cs`（3503 行，**0 个 DllImport**）
的 26 个回调装配（`:3295-3325`），在没有原生引擎时**全是死代码**。

**⚠️ 无 Windows shaping 真值可对拍**：`tests/parity/windows/` 全是**场景级**渲染对拍（15 个 scene PNG + DUCE 命令流）。
扫 7 个 `.stream`（含 `tests/U1-golden/`）：`MilCmdGlyphRunCreate(0x3a)` 只在 2 个文件各出现 1–2 次，
是场景里的**字形资源命令**，不是"同一串文本的 DWrite 步进基准"。
⇒ 要真值必须在 Windows 上跑 `IDWriteTextLayout` 导出 glyph id + advance（**目前没有**，属未闭环项）。

**落地建议**：见 §2.6 的两步正解；路线取舍的实测依据（M0–M6 七条对照 7/7）见
`build/MilBridge/T1-report.md` 的「M7c4 路线决策报告」节；复现 `bash build/MilBridge/run.sh hb`。

## 3. 边界说明（不是"没做"，是**不属于本组**）

以下项目常被误认为未实现，特此澄清：

| 项 | 归属 | 状态 |
|---|---|---|
| 25 条 `MilDrawCommand`（0x3e–0x56）绘图指令 | **skia-render 组** | 本组只切分 `MilCmdRenderData`(0x18) 的外层结构，把内层字节原样交给 `MilDrawInstruction`，**不做任何绘图** |
| `MilCmdRenderData`(0x18) | mil-core | 只解外层（12 字节头 + `CbData`），内层字节按原始流交给渲染层 |
| 视觉树 → 像素 | **skia-render 组** | 本组产出 `MilVisual` 图，不碰 `SKCanvas` |
| X11 窗口 / 文本 | **window-text 组** | 本组不涉及 |

---

## 4. 运行时如何观察

`MilChannel` 上暴露了计数器，便于排查"命令发出去没效果"：

```csharp
channel.NotImplCommands      // 提交时返回 E_NOTIMPL 的命令数
channel.NotImplRegistry      // Dictionary<MilCmd, long>：哪个命令字被拒了几次
channel.FailedCommands       // 返回其它失败码的命令数
channel.CommittedCommands    // 成功解码执行的命令数
```

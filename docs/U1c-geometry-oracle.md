# U1c · 几何导出真机对拍报告（`MilUtility_*` vs `wpfgfx_cor3.dll`）

> 结论先行：**215 个用例逐输入对拍真身 DLL**。修掉 11 处我方偏差后，
> **168/215 完全一致**（134 逐位 + 34 浮点容差内），16 例"几何等价、发射顺序不同"，
> 10 例"上游输出未定义或我方刻意加固"，21 例"图形分解/展平密度不同（需后续 milestone）"。
> 判定口径与逐例明细见 `tests/parity/geometry/summary.md`。

---

## 1. 对拍面与用例数

对拍面 = `PresentationCore/System/Windows/Media/Composition.cs` + `UnsafeNativeMethodsMilCoreApi.cs`
里声明、且**真身 DLL 真的导出**的 15 个 `MilUtility_*`，加 1 个导出探测用例。

| 函数 | 用例 | 逐位 | 容差内 | 顺序 | 偏差 | 结构 |
|---|---|---|---|---|---|---|
| `MilUtility_ArcToBezier` | 29 | 5 | 21 | 0 | 3 | 0 |
| `MilUtility_PathGeometryFlatten` | 14 | 3 | 8 | 0 | 0 | 3 |
| `MilUtility_GeometryGetArea` | 19 | 14 | 5 | 0 | 0 | 0 |
| `MilUtility_PathGeometryCombine` | 22 | 11 | 0 | 10 | 0 | 1 |
| `MilUtility_PathGeometryHitTest` | 25 | 25 | 0 | 0 | 0 | 0 |
| `MilUtility_PathGeometryHitTestPathGeometry` | 7 | 7 | 0 | 0 | 0 | 0 |
| `MilUtility_PathGeometryOutline` | 10 | 2 | 0 | 5 | 0 | 3 |
| `MilUtility_PathGeometryWiden` | 16 | 1 | 1 | 1 | 1 | 12 |
| `MilUtility_CopyPixelBuffer` | 21 | 21 | 0 | 0 | 0 | 0 |
| `MilUtility_GetTileBrushMapping` | 23 | 18 | 0 | 0 | 5 | 0 |
| `MilUtility_PathGeometryBounds` | 11 | 11 | 0 | 0 | 0 | 0 |
| `MilUtility_PolygonBounds` | 4 | 4 | 0 | 0 | 0 | 0 |
| `MilUtility_PolygonHitTest` | 3 | 3 | 0 | 0 | 0 | 0 |
| `MilUtility_GetPointAtLengthFraction` | 10 | 8 | 0 | 0 | 1 | 1 |
| `ExportProbe` | 1 | 1 | 0 | 0 | 0 | 0 |
| **合计** | **215** | **134** | **34** | **16** | **10** | **21** |

**导出探测的附带结论**：真身 DLL **没有**导出 `MilUtility_GetArcBounds` /
`MilUtility_GetBezierBounds` / `MilUtility_GetQuadraticBezierBounds`（它们在
`WpfGfx/core/resources/PathGeometryWrapper.h` 里有声明，但不属于导出面），
`MIL3DCalcProjected2DBounds` 与 `MilGlyphRun_*` 都在。所以我方不需要补这三个。

真身身份：`C:\Program Files\dotnet\shared\Microsoft.WindowsDesktop.App\10.0.7\wpfgfx_cor3.dll`，
1,952,016 字节，sha256 `f4f7a44a3480c0b7b2d5a603cb7d0c41d9ae9b2633a8b30eb59f66a2697045f3`，
Windows 11 22631 / .NET 10.0.7 x64。

---

## 2. 方法

### 2.1 共享输入集
`tests/parity/geometry/cases.json`（215 例）两侧共用。几何数据以
**手搓的 `MIL_PATHGEOMETRY` 十六进制字节块**给出（`harness/GeometryCases.cs` 的
`PathDataBuilder` 按 `wgx_core_types.cs:1009-1060` 的字段布局独立写出），
**刻意不经过我方 `MilGeometryEngine.SerializePath`**——否则"序列化器有 bug"会伪装成
"几何实现有偏差"。

### 2.2 两侧 harness 源码逐字节相同
`tests/parity/geometry/harness/*.cs` 同时被三个地方编译：

| 编译点 | 用途 |
|---|---|
| `tools/GeometryOracle/`（Linux 控制台） | 生成 `cases.json`、跑我方实现、出对拍报告 |
| `C:\u1-geom\`（Windows 控制台，`windows-harness/Program.cs` + `Harness/*.cs`） | `NativeLibrary.Load(真身全路径)` + `Marshal.GetDelegateForFunctionPointer` 跑真身 |
| `tests/WpfGfx.Linux.Tests/Commands.Tests/GeometryOracleTests.cs`（`<Compile Include>`） | 活体复跑 + 断言 |

Windows 侧刻意**不用 DllImport 名字解析**：绝对路径 Load + `TryGetExport`，
导出缺失立刻暴露（探测结果见上表）。

### 2.3 判定口径

| 判定 | 含义 |
|---|---|
| `Identical` | 输出逐位相同 |
| `Close` | 浮点容差内相同（`Δabs ≤ 1e-6` 或 `Δrel ≤ 2e-5`；几何内部全程 float32，两侧算法不同） |
| `Reordered` | **几何等价**，但图形顺序/环内起点或绕向不同（图与图的置换 + 环内旋转 + 反向都试过） |
| `Deviation` | 真的不一样 |
| `Structural` | HRESULT 不同 / 输出键集合不同 / 值数组长度不同 |

另有**契约性排除**（不是"放过差异"，而是上游本来就没写）：

* `MilUtility_PathGeometryWiden` 的 `outFillRule`：`geometry_api.cpp:151-217` **没有**
  `*pOutFillRule = ...`（而 `Outline:254` / `Flatten:452` / `Combine:397` 都有）。
  用哨兵法验证过：把出参预置成 `0x5EED0001`，真机原样回吐该哨兵 → 该槽位从未被写过。
* `MilUtility_GetTileBrushMapping` 的 `contentToShape`：契约写明 `brushIsEmpty≠0` 时
  该出参必须被忽略（`TileBrush.cs:144`），真机在那个分支直接 `goto Cleanup`、不写它。

---

## 3. 两个 ABI 发现（值得单独记）

### 3.1 `MilUtility_ArcToBezier` 的按值结构体
它是唯一一个"按值传结构体"的导出（`MilPoint2D ptStart / rRadii / ptEnd`）。
文档对"16 字节 double 对走 XMM 还是走按引用传副本"的说法含混，所以三种形态都实现、
**各起一个进程**试（选错的那次会直接 `0xC0000005` 打崩进程，同进程 try/catch 拦不住）：

| 形态 | 结果 |
|---|---|
| `flat`（摊成 6 个 double） | ❌ `Fatal error 0xC0000005`（位置计数规则不匹配） |
| `struct`（`Pt2D` 按值） | ✅ 过契约自检 |
| `ref`（`Pt2D` 按引用） | ✅ 过契约自检 |

后两者**机器码层面等价**：对 16 字节的 double 对，CLR 传的是"调用方副本的指针"，
两种 C# 写法编译出的调用序列一致。这解释了为什么 WPF 自己的 P/Invoke 能工作。
契约自检第一版太弱（只查末点与 `cPieces`），退化直线分支（`cPieces==0` 时
`pPt[0]` 恰好等于 `ptEnd`）会假通过；加强为"`cPieces==1` 且贝塞尔中点落在半径 10 的圆上"后
才有区分度——**这条经验写进 harness 注释了**。

### 3.2 `MilUtility_PathGeometryCombine` 三个矩阵都必须非 NULL
该导出对 7 个指针做 `IFCNULL`，而 `#define IFCNULL(obj) CHECKPTRHRGOTO(Cleanup,(obj),E_HANDLE)`
→ 传 NULL 得到 `E_HANDLE(0x80070006)`。**但 SAL 注释写的是 `__in_ecount_opt(1)`（可选）**
——注释与实现矛盾，上游自己从不传 NULL（`PathGeometry.InternalCombine` 永远传 `&matrix`）。
第一版用例有三个矩阵都省了，22/22 全回 `E_HANDLE`；显式给单位矩阵后 22/22 回 `S_OK`。
`CShapeBase::Combine` 本身是允许 NULL 矩阵的（`shapebase.cpp:656-659` "Optional, NULL OK"），
要求来自导出包装层。

---

## 4. 修复记录（11 处，每处三段证据）

全部改动集中在 `src/WpfGfx.Linux/Interop/`（`MilNative.Geometry.cs`、`MilGeometryEngine.cs`、
`MilExportTypes.cs`）与 `src/WpfGfx.Linux/Rendering/PathGeometryParser.cs`。

### F1 `MilUtility_GeometryGetArea`：自交图形面积
* **真机**：`area_bowtie_*` 三个用例 EvenOdd/Nonzero 都是 **50**（两瓣各 25）
* **修改前**：**100**
* **修改后**：**50**
* 根因：扫描线只按**顶点 y** 分带。蝴蝶结的自交点在 y=5（两条边交于 x=5），不在顶点集合里，
  于是整段 0..10 是一个带、中点上取到两条重合 crossing，parity 前缀扫描把两瓣之间的空隙
  也算成内部。修法：把**所有真交点的 y** 也作为分带边界（`AddSelfIntersectionYs`，
  含包围盒预筛与规模保护）。

### F2 `MilUtility_PathGeometryHitTest`：阈值语义三处
* **真机**：`hit_relative_tol`（距离 5.0、阈值 5.0，fRelative）→ **不命中**；
  `hit_rect_just_outside_no_tol`（距离 0.001、阈值 0）→ **命中**
* **修改前**：前者 **命中**（用了 `≤`），后者命中（因为容差 0 被兜底成 0.1）
* **修改后**：0 / 1，与真机一致
* 根因三条：①上游比较是**严格小于**（`FigureTask.cpp:209`、`:252` 都是 `<`）；
  ②`CHitTest` 把平方阈值下限钳在 `SQ_LENGTH_FUZZ=1e-4`（即距离下限 **0.01**）；
  ③阈值绝对化用 `CShapeBase::GetAbsoluteTolerance`（`shapebase.cpp:1561`）——
  `fRelative ? max(t,1e-12)*extent : max(t, extent*1e-12)`，**没有"容差 0 取 0.1"这种兜底**。

### F3 `MilUtility_PathGeometryHitTestPathGeometry`：极性与"完全相同"
* **真机**：`(大,小)` → **3 (FullyContains)**；`(小,大)` → **2 (FullyInside)**；
  **两个相同形状 → 4 (Intersects)**
* **修改前**：2 / 3 / 2（极性与"相同"两处都反）
* **修改后**：3 / 2 / 4
* 根因：原生写出的就是 `MilPathsRelation` 的值（`Disjoint=1/IsContained=2/Contains=3/Overlap=4`，
  `wgx_render_types_generated.h:75`），与 `IntersectionDetail` 数值一一对应，**没有映射层**。
  判定视角是**参数 1**：2 = "path1 在 path2 里"，3 = "path1 装下 path2"。
  枚举的 XML 文档是按托管 API（target=this=参数1）写的，照着文档推容易反。
  另外上游没有任何"相等"分支：两个差集都为空时走的是"重合边界 → 一边既有 inside 又有 outside
  → Overlap"。修法：两个差集都为空 → `Intersects`。

### F4 `MilUtility_PathGeometryBounds`：`fSkipHollows` 真的生效
* **真机**：含一个不可填充图形时 `skipHollows=true` → **(0,0,10,10)**，`false` → (0,0,200,200)
* **修改前**：true 也给 **(0,0,200,200)**（参数被接受但忽略，`docs/unimplemented.md` 曾如实登记）
* **修改后**：**(0,0,10,10)** / (0,0,200,200)
* 根因：上游一路传到 `CShapeBase::GetFillBounds(rect, fFillOnly, pMatrix)`，
  那里 `if (!fFillOnly || figure.IsFillable())`（`shapebase.cpp:1438`）。
  修法：`PathGeometryParser.Parse` 增加 `fillableOnly` 参数，按 figure Flags 的
  `IsFillable(0x8)` 过滤。`PolygonBounds` 无图形标志（`AddFigureFromRawData` 造出的图形恒可填充），
  所以那个导出忽略该参数是对的。

### F5 `MIL_PEN_DATA.DashArraySize` 是**字节数**，不是元素个数
* **真机**（16 字节 = 2 个 double）：50 长的线 + 笔宽 4 + dashes `[2,1]` → **5 个图形**
* **修改前**：**1 个图形**（完全没虚线）
* **修改后**：**5 个图形**
* 根因：上游 `UINT cDash = pData->DashArraySize / sizeof(double)`
  （`geometry_api.cpp:141`），托管侧写 `count * sizeof(double)`（`DashStyle.cs:71`）。
  初版按元素个数解释 → 2/8 = 0 条 → 虚线失效。修法：按字节换算，
  并补上上游的"奇数条复制一遍"与"每条取 `fabs`"（`cpen.cpp:292`、`strokefigure.cpp:3705`
  的 `GetDash(i) * rPenWidth`）。

### F6 `MilUtility_PathGeometryWiden`：笔宽 0 / 负笔宽
* **真机**：笔宽 0 → `HRESULT=S_OK` + **0 个图形**；笔宽 −2 → 与 +2 **同形**
* **修改前**：`E_FAIL`（Skia 把 `StrokeWidth=0` 当 hairline，`GetFillPath` 失败）/ 负宽同 0
* **修改后**：`S_OK` + 0 图形 / 与 +2 同形
* 根因：上游 `InitializePen` 原样塞 `Thickness`，`WidenToSink` 用 `pen.IsEmpty()` 提前返回；
  宽度取 `fabs`。修法：`CreateStrokePaint` 用 `Math.Abs(thickness)`；
  `Widen` 在厚度为 0 时返回空 `SKPath`（S_OK + 0 图形）。

### F7 `MilUtility_PathGeometryWiden`：矩阵先作用于几何，再描边
* **真机**：`widen_dash_scale_matrix`（几何 ×2、笔不缩放、虚线周期 8/4）→ **9 段**
* **修改前**：**5 段**（先描边后变换，虚线周期被一起放大）
* **修改后**：**9 段**
* 根因：契约 `pMatrix applied to the geometry but not to the pen`（`geometry_api.cpp:154`），
  上游把矩阵交给 `PathGeometryData` 构造参数后才 `WidenToShape`。修法：换序。

### F8 `MilUtility_PathGeometryBounds` / `PolygonBounds`：同 F7 的顺序
* **真机**：矩形 0..100、几何矩阵 ×2、笔宽 2 → **(-1,-1,201,101)**
* **修改前**：**(-2,-2,202,102)**（外扩量被矩阵一起放大）
* **修改后**：**(-1,-1,201,101)**
* 根因：上游 `shape.AddFigureFromRawData(..., &matGeometry)` 先变换几何，
  再 `GetTightBounds(rect, pen, matWorld, ...)`（`geometry_api.cpp:519/521`）。

### F9 `MilUtility_PathGeometryCombine`：`outFillRule` 恒为 Nonzero + 轮廓集规范化
* **真机**：22/22 个用例都回 **1 (Nonzero)**，与输入 fillRule 无关
* **修改前**：回 `FillRuleOf(Skia Op 结果)`（EvenOdd/Nonzero 不定）
* **修改后**：恒 **Nonzero**
* 根因：`*pOutFillRule = combinedShape.GetFillMode()`，而 `combinedShape` 是新建 `CShape`，
  默认填充模式 `m_eFillMode = MilFillMode::Winding`（`shape.h:57`、`shape.cpp:225`）。
  附带的**连锁问题**：Skia 的 Op 结果用 EvenOdd 表达"捏合"边界（相交矩形的 XOR 被写成
  "8 字形合并轮廓 + 反向公共方块"，只有 EvenOdd 下互相抵消）。改成 Nonzero 后，
  同样输入的 XOR 面积从 **150 变成 175**。修法：Op 结果为 EvenOdd 时先 `Simplify`
  规范成"互不重叠、朝向一致"的轮廓集——产物形态与真机一致（每块一个干净轮廓），
  面积回到 **150**，`MilExportTests.PathGeometryCombine四种模式的面积都正确` 重新通过。

### F10 闭合图形的编码：显式收口段、不盖 `SegClosed` 位
* **真机**：`combine_overlap_intersect` → **5 点 / 4 个 `Line` 类型**（末点 = 起点，无 0x10 位）
* **修改前**：**4 点 / 类型末位 17 (Line|SegClosed)**（`outline_rect`、`combine_overlap_union` 同理）
* **修改后**：5 点 / 4 类型，与真机一致（Combine 的 4 个"长度不同"用例全部转好）
* 根因：上游把"回到起点"当成一条**普通段**，闭合语义只由回调的 `isClosed` 表达。
  修法：`EmitPathFigures` 不再盖 `SegClosed`，闭合且末点未回到起点时补一个普通 `Line` 段。

### F11 `MilUtility_GetTileBrushMapping`：Bottom 对齐用 viewport 高度
* **真机**：viewport 100×100、viewbox 50×50、Uniform、Right+Bottom → `M42 = 0`
* **修改前**：**M42 = −50**
* **修改后**：**M42 = 0**
* 根因：一处复制粘贴错误——`case MilAlignmentY.Bottom:` 里写成了
  `alignY = viewport.Y + **viewbox**.Height`（同一 switch 的 `halign` 分支用的是
  `viewport.Width`，这里被抄错）。上游是 `prcViewport->Y + prcViewport->Height`
  （`TileBrushUtils.cpp:329-333`）。viewport 与 viewbox 高度相等的输入会掩盖这个错。

---

## 5. 未修的偏差（需主控决策 / 后续 milestone）

| # | 用例 | 真机 vs 我方 | 根因与建议 |
|---|---|---|---|
| U1 | `flatten_circle_tol_0{,_001,_25}` | 点数 8194/1266/98 vs 130/1502/114 | **展平算法不同**（上游 `CBezierFlattener` 有自己的细分上限与点数策略）。顺带一条：容差 0 时上游 `GetAbsoluteTolerance` 给 `extent*1e-12`（≈1e-10，几乎全精度展平），我方 `ResolveTolerance` 兜底成 0.1。**不建议现在改**：改 `ResolveTolerance` 会波及 Area/Bounds/HitTest，且我方的递归展平深度上限是 2^20、真机是每曲线约 1024 段，直接对齐会炸点数。建议单开 milestone：移植上游展平器 + 把深度上限调到 10。 |
| U2 | `widen_rect_pen2*`、`widen_with_matrix`、`widen_negative_thickness`、`widen_rect_tol_*` | 真机 **1 个**带接缝的闭合轮廓（24/23/31/19/227 点）vs 我方 **2 个**轮廓（外圈+内圈） | **描边轮廓的图形分解不同**（同一个区域、不同的图形划分）。Skia 的 `GetFillPath` 天然给两条轮廓；要一致得自写 widener 或做轮廓重建。一并解释 `widen_rect_tol_*` 的另一个差异：**Widen 的 `rTolerance` 上游是真用的**（tol=0.001 → 1267 点，tol=10 → 19 点），我方忽略它（`docs/unimplemented.md` 里"Widen 忽略 rTolerance"这条被真机**否证**）。 |
| U3 | `widen_open_line_pen2_square`、`widen_open_line_pen2_round` | 9 点 vs 6 点；圆头 32 处数值差 | 端帽（square/round）的离散化与顶点表不同。方形帽真机 9 点、我方 6 点；圆头帽的弧离散化精度不同。 |
| U4 | `widen_dash*`、`widen_dashed_rect` | 图形数一致（5/5、9/9、67 vs 66），但每段 5 点 vs 4 点 | 虚线段上游是"4 角 + 显式收口"的 5 点闭合图形，我方是 4 点 + `Close`。闭合矩形虚线还差 1 段（67 vs 66，接缝处）。 |
| U5 | `outline_bowtie_*`、`outline_nested_nonzero` | 真机 2 个图形 vs 我方 1 个（bowtie）；nested_nonzero 反过来 | **Outline 的图形分解不同**：真机把自交消解结果拆成两个独立闭合图形，我方合成一个（几何等价性未被完全验证）。 |
| U6 | `combine_touching_union` | 7 点 vs 6 点 | 共边相接的两个矩形做 Union：真机在接缝处多留一个共线顶点。 |
| U7 | `length_circle_0_3` | 点 (-3.0910, 9.5131) vs (-3.1091, 9.5072)，Δrel 0.58% | **弧长参数化不同**：上游 `CAnimationPath` 有自己的展平与长度累积。要一致得移植 `AnimationPath.cpp`。 |
| U8 | `length_line_nan` | 真机 `S_OK` + 点 `(NaN,NaN)` + 切线 `(1,0)`；我方 `E_FAIL` | NaN 分数的行为只能从一个数据点反推，**不擅自改**。若主控认为需要，建议按"NaN 分数 → 返回起点切线方向 + NaN 点"实现并再加用例。 |

---

## 6. 上游自身的问题（如实记录，不是我方偏差）

1. **`MilUtility_PathGeometryWiden` 从不写 `outFillRule`**（哨兵实测）。托管调用方
   `Geometry.GetWidenedPathGeometry` 把 `fillRule` 作为 `out` 传进去、随后
   `new PathGeometry(list.Figures, fillRule, null)`——在 IL 层面 `out` 的初始化赋值是死代码，
   于是托管侧读到的是**栈垃圾**。这是上游的一处真实疏漏（加宽结果通常是互不重叠的闭合轮廓，
   两种规则往往等效，所以一直没暴露）。我方给出**确定性值**（输入填充规则）并在此登记。
2. **`MilUtility_ArcToBezier` 半径退化时拷贝未初始化栈内存**：半径被 `AcceptRadius` 拒收时
   `ArcToBezier` 直接 `goto Cleanup`，`MilPoint2F points[12]` 从未被写；
   而 `MilUtility_ArcToBezier` 在 `cPieces >= 0` 分支照样 `pPt[0] = points[0]`
   （`geometry_api.cpp:901-918`）。真机给的是 `-5.48e-36` 这种非规格化垃圾值。
   我方写 `ptEnd`（确定性），并登记为"上游输出未定义"。
3. **`MilUtility_PathGeometryCombine` 的 SAL 注释与实现矛盾**：三个矩阵标成
   `__in_ecount_opt(1)`，实现里却 `IFCNULL`。
4. **`MilUtility_GetTileBrushMapping` 的 0 面积矩形会除零**：`IsRectEmptyOrInvalid` 只认
   "Rect.Empty 形态 / 含 NaN / 负宽高"，**0 宽或 0 高不算空**，紧接着
   `Viewport.Width / Viewbox.Width` 就除零，产出 INF/NaN 矩阵。
   我方刻意加固（把 0 宽高并入"空"判断，宁可少画也不产出 NaN 矩阵）——这是**有意保留的差异**，
   5 个 `tb_zero_*` 用例就是它的证据。**需要主控确认这个加固是否符合产品口径**。

---

## 7. 剩余存疑 / 没验到的部分（诚实清单）

1. **`MilGlyphRun_GetGlyphOutline` / `MilGlyphRun_ReleasePathGeometryData` 没对拍**：
   需要真身字体对象（`IntPtr pFontFace`），本次没有构造路径，只验了导出存在。
   任务书里写的是"必要时对拍"——本次没做。
2. **`sideways` 参数（`MilGlyphRun_GetGlyphOutline` 的侧向排版）完全没验**。
3. **`fSkipHollows` 只在 `PathGeometryBounds` 上验了**；`PolygonBounds` 的该参数按
   "无图形标志 → 恒可填充"推断为无影响，未用真机验证（用例里两种取值都给了，结果一致）。
4. **`rTolerance` 在 `Outline` 上确实没影响**（`outline_circle_tol_0.001/0.1/10` 真机都是 13 点），
   这条初版判断是对的；但在 `Widen` 上**被否证**（见 U2）。`Combine` 的 `rTolerance`
   只影响曲线展平（`CRelation` 把它当 flattening tolerance），我的用例里没有曲线输入，
   所以**没验到**。
5. **`Combine` 的曲线输入、`Exclude` 的孔洞拓扑**只在矩形上验过；曲线组合未覆盖。
6. **`GetPointAtLengthFraction` 的 `fRelative` 参数**不存在于该导出签名（只有 `rFraction`），
   已在用例里去掉；切线的归一化约定（是否单位向量）只在直线/圆上验过。
7. **`CopyPixelBuffer` 21/21 全一致**，但都是小缓冲；`height` 极大的溢出用例
   （`cpb_overflow_stride`）只验了错误码一致，未验证"是否写过输出缓冲"的侧信道。
8. **Windows 侧 harness 的构建偶然性**：本次踩了两次"`dotnet build` 没重建导致结果文件是旧的"
   （一次是 scp 后 mtime 造成构建跳过）。后续复现时请**先 `del bin\Release\net10.0\u1geom.dll`
   再 build，并检查 build.log**。已在报告里如实记录，最终数据是强制重建后的结果。

---

## 8. 产物清单

```
docs/U1c-geometry-oracle.md                     ← 本文件
tests/parity/geometry/
  cases.json                 215 例共享输入集（sha256 6398a637…）
  windows-results.json       真身输出（含 dll sha256 / ABI 形态 / 缺失导出）
  linux-results.json         我方输出
  summary.json / summary.md  逐例判定 + 差异明细（自动生成）
  show.py                    单例对照查看器（python3 show.py <case-id>）
  harness/                   两侧共用的 harness 源码
    GeometryCases.cs           用例模型 + MIL_PATHGEOMETRY 手搓构造器 + JSON 工具
    CaseCatalog.cs             215 例的生成器
    GeometryRunner.cs          runner 抽象 + 结果编码 + 比较器（含未定义输出排除）
    LinuxGeometryRunner.cs     调用我方 MilNative.MilUtility_*
    NativeGeometryRunner.cs    真身调用（NativeLibrary.Load + GetDelegateForFunctionPointer）
  windows-harness/           C:\u1-geom\ 的源码（Program.cs + GeometryOracle.Win.csproj）
tools/GeometryOracle/        Linux 侧驱动（generate / run / compare / one）
tests/WpfGfx.Linux.Tests/Commands.Tests/GeometryOracleTests.cs   活体复跑 + 回归断言
```

被修改的产品代码（全部在 `src/WpfGfx.Linux/`）：
`Interop/MilExportTypes.cs`（DashArraySize 语义）、`Interop/MilGeometryEngine.cs`
（Area 分带、笔→paint、Widen 0 厚度、TileBrush Bottom 对齐、Combine 的 Simplify）、
`Interop/MilNative.Geometry.cs`（F2/F3/F4/F5/F6/F7/F8/F9/F10）、
`Rendering/PathGeometryParser.cs`（`fillableOnly`）、
`tests/.../MilExportTests.cs`（`HitTestPathGeometry` 极性期望值）、
`tests/.../WpfGfx.Linux.Commands.Tests.csproj`（`<Compile Include>` harness）。

---

## 9. 复现步骤

```bash
export PATH="$HOME/.dotnet:$PATH"; cd <REPO>

# 1) 生成输入集 / 跑我方实现 / 出对拍报告
dotnet run --project tools/GeometryOracle -- generate tests/parity/geometry/cases.json
dotnet run --project tools/GeometryOracle -- run tests/parity/geometry/cases.json \
                                             tests/parity/geometry/linux-results.json
dotnet run --project tools/GeometryOracle -- compare tests/parity/geometry/cases.json \
        tests/parity/geometry/windows-results.json tests/parity/geometry/linux-results.json \
        tests/parity/geometry/summary.json tests/parity/geometry/summary.md

# 2) Windows 侧（C:\u1-geom\，源码见 tests/parity/geometry/windows-harness）
#    del bin\Release\net10.0\u1geom.dll & dotnet build -c Release & ^
#    bin\Release\net10.0\u1geom.exe cases.json windows-results.json
#    然后拷回 tests/parity/geometry/windows-results.json

# 3) 门禁
dotnet test tests/WpfGfx.Linux.Tests/Commands.Tests/
```

ABI 自检（换 ABI 形态时先跑这个，选错会打崩进程）：
`u1geom.exe selfcheck struct|ref|flat`

---

## 10. 门禁状态

```
dotnet test tests/WpfGfx.Linux.Tests/Commands.Tests/
→ 失败 0，通过 551，跳过 1，总计 552
```

* 基线是 542 通过 / 1 跳过；本次 **+9** 条用例（`GeometryOracleTests.cs`：
  1 条真机对拍 + 8 条回归断言），全部通过 → 551 通过 / 1 跳过。跳过的仍是
  `GoldenBinaryReplayTests`（`tests/U1-golden/` 当前没有 `.stream`，发现期 Skip）。
* `MilExportTests` 192 条全部通过，其中 `HitTestPathGeometry四种交集细节` 的期望值
  已按真机纠正（见 F3）。
* 强制 clean 重建（`dotnet clean` + `dotnet build-server shutdown` 后重跑）结果一致，
  不是增量构建的假象。

### 10.1 一个如实记录的插曲
本次会话进行到中途（14:48），并行工作的另一个 agent 往 `tests/U1-golden/` 放入了
`u1a-scenes-rtb.stream`，`GoldenBinaryReplayTests` 于是从"跳过"变成"执行"并失败：
`GoldenBinaryReplayTests.cs:146` 的 `Assert.Equal(HResult.S_OK, hr)` 实际得到
`0x80070006 (E_HANDLE)`。E_HANDLE 在这条链路上只能来自
`MilCommandDispatcher.cs:1375/1397` 的**目标句柄查表失败**（命令/资源层），
几何函数根本不返回 E_HANDLE，因此判定**与本次改动无关**——按边界我没有动
`tests/U1-golden/`。15:08 该 agent 撤走了那个流文件（目录里换成 PROVENANCE.md + README.md），
用例回到发现期 Skip，门禁随之全绿。这一段保留在报告里，是为了说明"曾经红过、红在哪、为什么不是我的"。

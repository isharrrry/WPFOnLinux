# U1a 对照报告：真机 Windows WPF ↔ 我们 Linux 渲染栈（像素级）

> 这是本工程**第一次拿真机像素当 oracle**。真机数据（15 场景 / 15 PNG / 110 探针）由
> `tests/parity/windows/` 提供，采集侧已独立校验（`verify_u1a_data.py`：15/15 SHA256、
> 110/110 探针重采样一致）。本报告的全部数字都可用下面一条命令复现：
>
> ```bash
> export PATH="$HOME/.dotnet:$PATH"
> dotnet test tests/WpfGfx.Linux.Tests/Rendering.Tests/ -m:1 \
>   --filter "FullyQualifiedName~ParityTests"
> ```
>
> 数据缺失时整套用例在**发现期**跳过（`ParityFactAttribute`，写法与理由照抄
> `Windowing.Tests/X11Guard.cs`），不会把无数据的机器染红。

---

## 0. 摘要

| 指标 | 结果 |
|---|---|
| 场景 | 15/15 重建并比对（我方 MilVisual + MilRenderData + SkiaRenderBackend，走真实 MilResourceTable） |
| 探针 | **110/110 通过**（Δ≤2，真机实测值） |
| 全图差异像素（Δ>2） | **10854 / 983040 = 1.104%**，其中 **121 个（0.012%）不在真机边缘 1px 内** |
| 完全一致（0 差异像素） | 4 个场景：scene01 / scene04 / scene05 / scene08 |
| 真机结论核对 | 三条**全部吻合**：sRGB 插值 ✓、PushOpacity 合成层 ✓、Exclude = A−B ✓ |
| 找到并修复的实现 bug | **1 个**（`SkiaBrush.MappingMatrix` 的 Concat 参数顺序写反 → 所有 `RelativeToBoundingBox` 渐变画刷全错） |
| 新发现、只报告未动手 | **1 个**（`TransformResolver.Mul` 的复合顺序与 WPF 相反 → `TransformGroup` 反序；见 §5.3） |
| 债务销账 | **#8（Exclude/Difference）可以销账**；**#7（Arc）建议降级保留**（逐项量化见 §5.1） |

---

## 1. 方法：口径先钉死，再看数字

### 1.1 op 树是唯一真源

真机侧 `U1Parity` 用同一棵 op 树既渲染又序列化 `scenes.json`（`Scenes.cs` 注释：
"the SAME tree is fed to the renderer"）。所以对照的正确做法**不是**看着 PNG 反推，
而是把同一棵树喂给我方栈。`ParityScenes.cs` 里的 `op → 指令` 映射逐条对着
`tests/parity/windows/src/U1Parity/R.cs` 抄，没有一处凭描述手写：

| op | 真机（DrawingContext） | 我方 |
|---|---|---|
| `rect` | `DrawRectangle` | `MilDrawRectangle` |
| `roundrect` | `DrawRoundedRectangle` | `MilDrawRoundedRectangle` |
| `ellipse` | `DrawEllipse` | `MilDrawEllipse` |
| `line` | `DrawLine` | `MilDrawLine` |
| `linearGradient` / `radialGradient` | `DrawRectangle(brush, …)` | `MilDrawRectangle` + 渐变画刷 |
| `path` | `DrawGeometry(PathGeometry)` | `MilDrawGeometry` + `MilPathGeometry`（序列化字节） |
| `combine` | `DrawGeometry(CombinedGeometry)` | `MilDrawGeometry` + `MilCombinedGeometry` |
| `clip` | `PushClip` ×n / `Pop` ×n | `MilPushClip` ×n / `MilPop` ×n |
| `opacity` | `PushOpacity` / `Pop` | `MilPushOpacity` / `MilPop` |
| `transform` | `PushTransform` | `MilPushTransform`（矩阵取 `scenes.json.composite`） |

颜色走 `SkiaColor.MakeScRgb`（sRGB 字节 → scRGB 浮点），与真机
`Composition.cs: color.r = c.ScR` 同一趟变换；探针/坐标口径全部取自 `conventions`。

### 1.2 三档容差（`ParityCompare.cs`）

| 档 | 判据 | 用途 |
|---|---|---|
| tight | 单通道 Δ≤2 | 主判据（= 既有 `ImageComparer.DefaultTolerance`），跨实现比对的舍入余量 |
| loose | Δ>16 的像素数（"AA 容差"之上） | 真机自证：同一场景同一拓扑、只有 `IsLargeArc` 不同也会产出 245/16384 差异像素、最大通道差 44（`docs/U1-windows-probe.md` §2.5），所以边缘像素上的中等差值不可归咎实现 |
| **interior** | Δ>2 **且**在真机图 8 邻域内不存在 >8 的通道跃变 | **"语义错"判据**。边缘图只从**真机图**算，不允许拿我方的边缘去豁免我方的错；阈值取 8 是故意从严 |

`interior` 这一档是"不可归咎"判定的核心：它把"差异是否只发生在真机自己的颜色边界
1 像素之内"变成一个可计算、可复现的布尔量，而不是靠肉眼看 diff 图。

### 1.3 差异图

`tests/parity/linux/diff/<scene>.diff.png`，仿 `ImageComparer.CreateDiff` 但多一档：
**红 = Δ>16**（超出 AA 容差，必须解释）、**黄 = 3..16**（边缘/取样差异）、
**暗底 = 真机图压暗到 35%**（一眼看出差在哪儿）。

---

## 2. 15 场景对照总表

| 场景 | 差异像素 Δ>2 | 占比 | 非边缘 Δ>2 | 最大通道差 | Δ>16 | 探针 | 归类 |
|---|---:|---:|---:|---:|---:|---:|---|
| scene01_solid | 0 | 0.000% | 0 | 0 | 0 | 7/7 | ①完全一致 |
| scene02_roundrect | 300 | 0.458% | 0 | 47 | 108 | 7/7 | ③AA/取样 |
| scene03_ellipse | 942 | 1.437% | 0 | 79 | 464 | 7/7 | ③AA/取样 |
| scene04_linear_gradient | 0 | 0.000% | 0 | **1** | 0 | 7/7 | ①完全一致 |
| scene05_radial_gradient | 0 | 0.000% | 0 | **1** | 0 | 6/6 | ①完全一致（修 bug 后） |
| scene06_dash | 1080 | 1.648% | **118** | 255 | 960 | 9/9 | **②已知简化（DashCap）** |
| scene07_opacity | 336 | 0.513% | 0 | 30 | 36 | 8/8 | ③AA/取样 |
| scene08_clip_rect | 0 | 0.000% | 0 | 0 | 0 | 6/6 | ①完全一致 |
| scene09_clip_path_fillrule | 1622 | 2.475% | 0 | 49 | 504 | 8/8 | ③AA/取样 |
| scene10_transform | 843 | 1.286% | 0 | 52 | 213 | 8/8 | ③AA/取样 |
| scene11_arc_sweep_large | 1842 | 2.811% | 0 | 88 | 556 | 8/8 | ③AA/取样 |
| scene12_arc_ellipse | 713 | 1.088% | 0 | 100 | 293 | 8/8 | ③AA/取样 |
| scene13_arc_degenerate | 929 | 1.418% | 0 | 212 | 521 | 9/9 | ③AA/取样 + miter 突刺（§5.1-D3/D4） |
| scene14_combine_union_xor | 1325 | 2.022% | **3** | 85 | 599 | 6/6 | ③AA/取样 |
| scene15_combine_intersect_exclude | 922 | 1.407% | 0 | 81 | 274 | 6/6 | ③AA/取样 |
| **合计** | **10854** | **1.104%** | **121** | — | 4528 | **110/110** | — |

### 2.1 归类统计

| 类 | 场景数 | 差异像素 | 占比 |
|---|---:|---:|---:|
| ① 完全一致（0 差异像素） | 4 | 0 | 0% |
| ② 已知简化（我方代码里已诚实标注） | 1（scene06） | 1080（其中 118 非边缘） | 0.110% |
| ③ AA/取样差异（全部落在真机边缘 1px 内） | 10 | 9774 | 0.994% |
| ④ 场景规格歧义 | **0** | 0 | 0% |
| （修复项）我方实现 bug，已修 | 1（scene05 修前） | 修前 35137 → 修后 **0** | 修前 53.6% |

> ② 的 1080 px 里，118 个"非边缘"全部来自 scene06 的 0 长度虚线圆点；
> ③ 的 9774 px 全部落在真机边缘 1px 内，其中 scene13 里有 ~216 px 是 180° 折返处的
> miter 裁剪突刺（已单独归因，见 §5.1-D3/D4），扣掉它纯 AA 差异为 9558 px；
> ④ 为空——`conventions` 把口径写全了，没有需要"猜规格"的差异。

**没有一个是"规格歧义"**：`conventions` 节把坐标/颜色/插值/虚线/矩阵/弧线口径都写全了，
110 个探针的期望值也全部命中。这是我们能给出"哪一类"的前提。

### 2.2 "不可归咎"（③）的判定依据

不是"看着像 AA 就算 AA"，而是三条可复现的判据同时成立：

1. **位置**：差异像素全部落在真机图边缘 1 像素邻域内。判据 `jump>8`（= 套件里
   `ParityCompare.EdgeJumpThreshold`）下：除 scene06 的 118 px 与 scene14 的 3 px 外，
   其余场景的非边缘差异**全为 0**。
2. **方向**：差异是**双向**的（同一场景里既有"我方少墨"也有"我方多墨"）。取样差异必然
   双向；漏画/多画一个图元只会单向。逐块统计（按"谁更接近背景色"分类）例如
   scene11 格(0,0) = 少墨 79 / 多墨 84、scene02 各格 = 少墨 4..18 / 多墨 4..41，全部双向；
   全表唯一单向的是 scene06（少墨 960 / 多墨 0）——正因为它不是 AA，而是漏画圆点（见 §4.2）。
3. **量级**：差异像素占该场景 0.46%–2.8%，且带宽只有 1–2 像素（曲边/斜边的覆盖率差），
   没有任何"整块位移/整块变色"。对照真机自证的 AA 波动（245/16384 = 1.5%、最大差 44），
   量级同阶。

scene14 的 3 个非边缘像素在 **x=255**（画布最右列），是圆弧被画布裁切处的覆盖率差，
最大 Δ 37；scene13 的 212 不是 AA（见 §5.1-D3/D4，已单独归因）。

---

## 3. 三条真机结论的我方实测核对

### 3.1 结论 1：渐变按 sRGB 插值 —— ✅ 完全吻合

| 采样点 | 真机 | 我方 | 线性 scRGB 反模型 |
|---|---|---|---|
| scene04 黑→白中点 (128,182)，t=0.5022 | `(128,128,128)` | **`(128,128,128)`** | 188 |
| scene04 三停靠带 (72,56)，t=0.2811 | `(111,144,0)` | **`(112,143,0)`**（手算 (112,143,0)） | (191,187,0) |

- 我方插值空间判定：`SkiaBrush.Stops()` 把停靠点转成 8 位 `SKColor` 后交给 Skia，
  Skia 在目标色彩空间（sRGB，gamma 域）插值 → 中点 128 ✓。
- **那条"ColorInterpolationMode 未实现"的注释到底差多少**：答案是**在本次覆盖到的两种
  模式下差 0**。真机 `GradientStop` 的默认 `ColorInterpolationMode` 是
  `ScRgbLinearInterpolation(0)`（`R.cs` 没设过），名字叫"scRGB 线性"，但实测行为
  **就是 sRGB gamma 域插值**——WPF 的命名与行为不一致，我们的实现（忽略该字段、按 sRGB
  插值）恰好落在行为正确的一侧。整场景差异 **0 像素、最大通道差 1**。
- 影响面：`ScRgbLinearInterpolation` 与 `SRgbLinearInterpolation` 两个枚举值在真机上
  **未被区分验证**（scene04/05/09 都用默认值）。若将来有人显式设置
  `ColorInterpolationMode=SRgbLinearInterpolation`，我方仍按 sRGB 插值——**这条仍是未验证
  的简化**，但按真机默认值的行为推断，风险很低。注释建议改写为
  "默认模式实测与 sRGB 插值一致；两个枚举值的区分未验证"。

### 3.2 结论 2：`PushOpacity` 是真·合成层 —— ✅ 完全吻合

scene07 组内重叠区 (122,150)（红底 + 两个 50% alpha 椭圆 + 组不透明度 0.75）：

| 模型 | 绿通道 | 证据 |
|---|---:|---|
| 真机（合成层） | **144** | `scenes.json` 探针实测 `(159,144,0)` |
| 我方 `MilPushOpacity` | **144** | `(159,144,0)`，Δ=0 |
| 逐图元乘 alpha（解析反模型） | 156 | `(159,156,0)` |
| 逐图元乘 alpha（**用我方栈真的画出来**） | 156 | 把 0.75 乘进两个子画刷 alpha 后重画 |

实现层面对得上：`SkiaRenderBackend.MilPushOpacity` →
`PushLayer(canvas, SKPaint{ Color = White.WithAlpha(AlphaByte(opacity)) })` →
`SKCanvas.SaveLayer`，是货真价实的离屏图层；`MilPop` → `Restore`。8 个探针全中，
整场景差异 336/65536 且**全部落在椭圆边缘 1px 内**（`jump>8` 下非边缘 = 0）。

> 说明：图层 alpha 用的是 `round(0.75×255)=191`（0.74902），与 WPF 的精确 0.75
> 理论上有 ≤0.1% 的偏差；实测未在任何探针上表现出来（Δ=0）。这是可接受的量化口径。

### 3.3 结论 3：`CombinedGeometry.Exclude` = A−B —— ✅ 完全吻合（债务 #8 可销账）

scene15 右格（`exclude`），基础色 `#FF00A060`：

| 区域 | 真机 | 我方 | 把 Exclude 当 Xor 画（反模型） |
|---|---|---|---|
| A 独占 (148,64) | `(0,160,96)` 填充 | `(0,160,96)` ✓ | `(0,160,96)` |
| A∩B 交叠 (196,64) | `(255,255,255)` 不填 | `(255,255,255)` ✓ | `(255,255,255)` |
| B 独占 (240,64) | `(255,255,255)` **不填** | `(255,255,255)` ✓ | **`(0,160,96)` 会填 ← 与真机相反** |

外加左格 `intersect` 三个区域全中（A 独占不填 / 交叠填 / B-only 不填），
以及 scene14 的 `union`（三区全填）与 `xor`（交叠不填）6/6 探针。

**结论**：`SkiaGeometry.PathOpOf(Exclude) = SKPathOp.Difference` 与真机逐像素一致
（右格差异 267/65536，全部在曲线边缘；`jump>8` 下非边缘 = 0）。债务 #8 的
"未经真机比对"前提已消失，**可以销账**。

---

## 4. 修复清单（每项三段证据）

### 4.1 【已修】`RelativeToBoundingBox` 画刷映射矩阵的参数顺序写反

**位置**：`src/WpfGfx.Linux/Rendering/SkiaBrush.cs` → `MappingMatrix()`
（2 行改动：`SKMatrix.Concat(Scale, Translate)` → `SKMatrix.Concat(Translate, Scale)`）

**根因**：`SKMatrix.Concat(a, b)` 的语义是 `a∘b`，即**先 b 后 a**（SkiaSharp 2.88.9 实测；
同文件 `TileBrushMapping` 的注释本来就写对了这条）。要把画刷的 `[0,1]²` 铺到几何包围盒，
必须**先缩放、后平移**，即 `a = 平移`、`b = 缩放`。写反之后平移被缩放乘了进去：
包围盒 `(8,8,116,240)` 得到 `Tx = 8×116 = 928`、`Ty = 8×240 = 1920`，整块渐变被推到
着色器空间的远处，`[0,1]` 之外一律钳位成末停靠色。

**三段证据**（scene05_radial_gradient，真机 RenderTargetBitmap）：

| | 差异像素 | 占比 | 探针 | 最大通道差 | 采样点 (66,128)（渐变中心） | (12,128)（左缘 t≈0.95） |
|---|---:|---:|---:|---:|---|---|
| 真机 | — | — | — | — | `(253,253,254)` | `(35,79,167)` |
| 改前 | 35137 | **53.615%** | **2/6** | 237 | `(16,64,160)`＝末停靠色 | `(16,64,160)` |
| 改后 | **0** | **0.000%** | **6/6** | **1** | `(253,253,254)` ✓ | `(35,79,167)` ✓ |

改后整块 116×240 渐变与真机**逐像素相同**（差异 0，最大通道差 1），不是"接近"。

**影响面（为什么以前没被发现）**：所有 `MappingMode = RelativeToBoundingBox` 的
线性/径向渐变画刷都走这一支；golden 图是自产的，`linear_gradient` 那条用例自己就
把 bug 固化了（相对渐变矩形是一片纯色＝首停靠色 `#FFFFFF00`）。修后该基准图必须重生成，
已用 `WPFGOLDEN_UPDATE=1` **只重跑该条用例**完成（影响面已核：新旧基准图差异 bbox
= `(20,95,130,165)`，正是那个相对渐变矩形，图像其余部分逐字节相同）。

**同步加的用例**：
- `ParityTests.relative_brush_mapping_puts_unit_square_on_bounds`：直接断言包围盒中心
  = 渐变原点（近白）、左缘 t≈0.95、角上被钳位，三点都对齐真机探针值。
- `GoldenRenderTests.linear_gradient`（既有用例，基准图重生成）：现在是真正的对角渐变。

### 4.2 【结论：**不改**】scene06 的 DashCap 差异（"不改"也是要留证据的结论）

`SkiaPen.cs` 已知简化 #1：`DashCap`（圆/方虚线端头）未实现。真机 scene06 里有 3 条
`dashCap: round` 的虚线。做了一次**受控实验**（临时把 `DashCap` 映射成
`SKPaint.StrokeCap`，测完已逐字节还原）：

| 方案 | 差异像素 | 非边缘 | 现象 |
|---|---:|---:|---|
| 现状（Butt，忽略 DashCap） | 1080 | **118** | 0 长度虚线（`[0,2,4,2]`、`[2,2,0,2]` 里的 0）在真机上是**圆点**，我方什么也不画（linux 白 / 真机 `#000080`，Δ=255） |
| 临时实验（DashCap→StrokeCap=Round） | 588 | 72（该轮按 jump>32 口径计） | 圆点画出来了，但线**两端**也被画成圆头，向外多出 3px（真机是 Flat 端头），换成另一类错 |
| 理想实现 | — | 0 | 需要手工按 dash 相位切段、逐段套不同端头（首段用 StartLineCap、中间用 DashCap、末段用 EndLineCap），Skia 的 `CreateDash` 表达不了 |

**结论**：不改。半个修复只是把 118px 的"漏画"换成 72px 的"多画"，净收益不明确；
真机数据恰好量化了这条已知简化的代价：**118 个非边缘像素 / 场景（0.18%），
且只影响 `DashCap != Flat` 的虚线**。已把该数字写进场景预算与注释。
（顺带确认：Skia 在 Round 端头下**确实**会画 0 长度虚线，所以将来做"手工切段"的
完整实现是可行的，只是不属于"局部且清晰"的修复。）

### 4.3 结论：本工程历史上第一次"用真机数据判定我方错"的收益

一个 2 行改动（§4.1）把 15 个场景里的**53.6% 像素差异降到 0**，并且顺带证明
`RelativeToBoundingBox` 这条路径此前**从未被任何真值校验过**（既有 golden 自我循环）。
这正是 U1a 的价值所在。

---

## 5. 债务处置建议

### 5.1 债务 #7（Arc 段未与真机比对）→ **建议降级保留**（结论已量化）

逐项（真机 256×256 位图 vs 我方；"该格"按场景自己的格子切：scene11 是 64×128，
scene12/13 是 128×128；"探针"列是"该格关联探针的失配数"）：

| 子项 | 场景/格 | 探针 | 该格 Δ>2 | 该格最大通道差 | 结论 |
|---|---|---|---:|---:|---|
| sweep×largeArc 4 组合 × 水平弦 | scene11 行 1（64×128 格） | 8/8 | 94 / 196 / 103 / 199（共 8192 格） | 37–55 | 曲线边缘覆盖率差，双向，量级与真机自证 AA 同阶 |
| sweep×largeArc 4 组合 × 斜弦 | scene11 行 2 | 8/8 | 358 / 317 / 282 / 293 | 63–88 | 同上（斜弦最差 358/8192 = 4.4%） |
| 椭圆弧 + rot 30/45/90 | scene12 4 格 | 8/8 | 134 / 279 / 107 / 193 | 31–100 | 同上（`rot45 large-cw` 最差 279/16384＝1.7%） |
| **D1 半径过小 → 等比放大**（rx10,ry5→40,20） | scene13 格(0,0) | 0 失配 | 188 | 59 | SVG F.6.6 的等比放大（×4 → rx40,ry20）与真机同拓扑：探针 (64,54) 填充、(64,74) 背景两点**逐点相同**，余下 188 px 全在放大后椭圆的边缘 |
| **D2 半径 == 弦/2，IsLargeArc=true** | scene13 格(1,0) | Δ=0 | 241 | 53 | 拓扑无操作 ✓ |
| **D2′ 同参数 IsLargeArc=false** | scene13 格(0,1) | Δ=0 | 248 | 66 | ✓ |
| **D3 rx=ry=0 → 直线** | scene13 格(1,1) | Δ=0 | 252 | **212** | 见下"miter 突刺" |
| **D4 rx=ry=5000 巨半径** | scene13 格(1,1) | Δ=0 | 252 | **212** | 同上 |

- **D2/D2′ 的"拓扑无操作"我方比真机更干净**：真机两格之间 245/16384 像素不同
  （最大通道差 44，纯 AA；按 Δ>2 计为 222）；**我方两格逐字节相同（0/16384）**。
  即"半径=弦/2 时 IsLargeArc 是拓扑无操作"这条，我方实现得比真机更严格一致。
- **D3/D4 新发现的真实差异（miter 突刺）**：这两个 figure 都是
  `起点 → 弧 → 闭合`，闭合线把路径**原路折返**，两端各有 180° 的折返角。
  真机用 `miterLimit(10) × 线宽(3) / 2 = 15px` 的 miter 裁剪，在两端各多画出一块
  15px×3px 的墨（实测：真机墨迹 x∈[137,246] 共 110px，我方 x∈[152,231] 共 80px，
  两侧各差 15px，共 ~216 像素"我方少墨"）。Skia 对 180° 折返画平头，不产生突刺。
  **这是光栅器 join 规则的差异，不是弧线求交/端点参数化的错误**——弧本身的位置、
  半径放大、端点都对得上（探针 Δ=0）。Skia 侧没有开关可以复现"平角 miter 裁剪"，
  修它需要自己构造描边几何，不建议为它动渲染层。
- **建议**：债务 #7 从"未与真机逐像素比对（存疑）"降级为
  **"已对照；弧线端点参数化/SVG 半径修正/椭圆弧旋转/sweep×largeArc 全部正确；
  残留仅两类不可由我方控制的光栅器差异（曲线边缘 AA、180° 折返的 miter 裁剪）"**。
  `PathGeometryParser.AppendArc` 的"存疑"注释可以改成指向本报告 §5.1。

### 5.2 债务 #8（`CombinedGeometry.Exclude` 映射存疑）→ **销账**

证据见 §3.3：真机 `exclude` 格 B 独占区**不填充**（对称差会填充），A 独占区填充，
交叠区不填充；我方 `SKPathOp.Difference` 与之逐像素一致，整场景 6/6 探针 + 非边缘差异 0。
建议把 `ARCHITECTURE.md` §8 第 8 行替换为：

> | 8 | ~~`CombinedGeometry.Exclude` 映射存疑~~ **已销账（U1a）** | 真机 scene15 判定 Exclude = A−B，`SKPathOp.Difference` 正确；`docs/U1a-parity-report.md` §3.3 | `SkiaGeometry.cs:129-136` |

### 5.3 【新债务 #12】`TransformResolver.Mul` 的复合顺序与 WPF 相反

**发现方式**：本报告顺带写了一条"拿 `scenes.json.composite` 当 oracle 反查我方矩阵"
的用例，第一次跑就红了。

**证据链**：
1. 真机 `scenes.json` 的 `composite` 是 WPF `Matrix.Multiply` 逐个乘出来的：
   `[S(1.5,0.75), R(-25°), T(140,140)] → composite = [1.35946…, -0.63393…, 0.31696…,
   0.67973…, 140, 140]`。上游源码可佐证：`WindowsBase/.../Matrix.cs:127` `Multiply(a,b)`
   是行向量 `a·b`（b 是平移时只加偏移），`TransformGroup.cs:31` `Value = c0*c1*…*cn`
   ⇒ **c0 先作用在几何上**。
2. 我方 `VisualProjection.Mul(a,b)` 的公式数值上 **= `SKMatrix.Concat(a,b)`**
   （实测：`Concat(R30,T30).TransX = 10.98`，而真机 composite 是 `30`）。
   `Concat(a,b)` 的语义是 `a∘b` = **先 b 后 a**——与 `Mul` 自己的 XML 注释
   "结果 = 先 a 后 b（行向量约定 p·a·b）"**正好相反**。
3. 于是两个调用点里只有一个是对的：
   - `AroundCenter(inner,cx,cy) = Mul(Mul(T(c),inner),T(-c))` → `T(-c)∘inner∘T(c)` ✔ **正确**（绕 c 变换）
   - `Resolve(MilTransformGroup)`: `acc = Mul(acc, child)` → `cn∘…∘c1∘c0` ✘ **反序**
     （WPF 要求 `c0` 先作用）
4. 影响面：`MilCmdTransformGroup(0x72)` 是真实存在的命令
   （`docs/duce-commands.txt:90`、上游 `Generated/TransformGroup.cs:226` 会发它），
   `VisualProjection.cs:38` 对每个 Visual 的 Transform 句柄都走 `TransformResolver.Resolve`。
   XAML 里常见的 `<TransformGroup><ScaleTransform/><RotateTransform/><TranslateTransform/></TransformGroup>`
   会被**按相反顺序**应用。
5. 本次 15 个场景**没有覆盖到**这条路径（scene10 的 transform 全部是 `PushTransform` +
   已经算好的 composite 矩阵），所以场景数字是干净的；23 个 transform op 里也只有
   2 个（scene10 的旋转/缩放两格，非交换）能区分顺序。

**建议的最小修法**（1 行，未执行）：
```csharp
// src/WpfGfx.Linux/Resources/VisualProjection.cs:118-119
foreach (DUCE.ResourceHandle child in g.Children)
    acc = Mul(Resolve(ch, child, depth + 1), acc);   // ← 参数换位
```
**为什么只报告不动手**：① 它落在 `Resources/`（不是本次授权的 `Rendering/`），
② 修完 `tests/golden/transform_nested.png` 基准图必然变化（那条用例用了
`TransformGroup(Translate(15,95), Scale(1.3,0.8))`），重生成基准图超出本次授权，
③ 同一支 `Mul` 还被 `AroundCenter` 依赖，需要一起审。约定：`ParityTests` 里的
`transform_matrix_composition_order_vs_wpf` 是一条**债务哨兵**——修好后它会失败，
提醒改动者把断言反过来并更新本节。

> 顺带记录一处**未验证的疑点**（不列为债务）：`SkiaBrush.BrushMatrix` 注释写
> "RelativeTransform 先作用，再 Transform"，但 `Concat(relative, transform)` 的实际语义是
> "transform 先作用"。本次 15 个场景没有画刷变换，真机数据无法裁决；建议在补场景时
> 一并验（见 §6）。

---

## 6. 未覆盖与剩余缺口

**采集侧已声明未覆盖**（`scenes.json` 的 `notCovered`）：文本/字形、位图 `ImageSource`、
`Blur`/`DropShadow` 效果、3-D、动画、窗口化合成。这些在本次对照里**同样没有被验证过**，
一条也不能算数。

**本次对照额外没覆盖到的（我方栈里有实现、但真机场景没碰）**：

| 项 | 原因 | 风险 |
|---|---|---|
| `MilVisual` 层级（Offset/Opacity/Clip 树） | 真机是单个 DrawingVisual，所有 op 都在同一段 DrawingContext 里 | 中：`world = Concat(Concat(parent,Transform),Offset)` 的复合顺序只能靠上游源码论证（本报告已核为正确），没有真机像素背书 |
| `MilTransformGroup` / `MilVisual.Transform` 句柄 | 同上（scene10 走 `PushTransform`） | **高**：见 §5.3，已确认为反序 |
| 画刷 `Transform` / `RelativeTransform` | 场景未设 | 中：见 §5.3 末尾疑点 |
| `SpreadMethod.Repeat` | scene04 只用 Pad/Reflect | 低（同一映射，只是 tile 模式） |
| 非 1:1 DPI、`EdgeMode`、`GuidelineSet` | 真机固定 96 DPI | 低 → 中（像素吸附在真实 XAML 里很常见） |
| 虚线奇数数组、`Pen.StartLineCap/EndLineCap` 不同 | 场景未出现 | 低（我方有宽容降级，与 WPF 的"拒绝渲染"不等价） |
| `GeometryGroup`、`IsFilled=false` 的 figure | scene09 有一个 `filled:false` 但 `fill:null`（不触发） | 低-中：我方 `PathGeometryParser` 不消费 `IsFillable`，只有"同一条 PathGeometry 里既有填充又有非填充 figure"时才暴露 |
| 位图/字形/效果/3D | 采集侧 notCovered | 未知 |

**建议的下一个真机场景批次**（按性价比）：
`TransformGroup` 反序复现（1 格就能定案 §5.3）、画刷 Transform/RelativeTransform、
`IsFilled=false` + 非空 fill、`Pen.StartLineCap/EndLineCap` 不同、位图 `DrawImage`。

---

## 7. 产物与文件清单

**新增（本次交付）**

| 路径 | 说明 |
|---|---|
| `tests/WpfGfx.Linux.Tests/Rendering.Tests/ParityScenes.cs` | scenes.json 只读加载 + op 树播放器（op→我方指令，逐条对齐 `R.cs`）+ PathGeometry 写侧 |
| `tests/WpfGfx.Linux.Tests/Rendering.Tests/ParityCompare.cs` | 三档容差比对、边缘图、差异图、分块/分区域统计 |
| `tests/WpfGfx.Linux.Tests/Rendering.Tests/ParityTests.cs` | 25 条用例：15 场景 + 结论 1/2/2b/3 + 债务 #7 三条 + 矩阵顺序哨兵 + 修复回归 + 汇总；含逐场景预算与分类表 |
| `tests/parity/linux/parity-results.json` | 机器可读结果（每场景差异数、逐探针 真机 vs 我方、分类） |
| `tests/parity/linux/README.md` | 该目录的读法与复现说明 |
| `tests/parity/linux/actual/*.png` | 我方 15 张渲染结果 |
| `tests/parity/linux/diff/*.png` | 15 张差异图（红 Δ>16 / 黄 3..16 / 暗底=真机图） |
| `docs/U1a-parity-report.md` | 本报告 |

**修改（有证据的修复）**

| 路径 | 改动 |
|---|---|
| `src/WpfGfx.Linux/Rendering/SkiaBrush.cs` | `MappingMatrix()` 参数换位（2 行）+ 注释写明真机证据，防止再被"顺手调正" |
| `tests/golden/linear_gradient.png` | 因上条修复重生成的**唯一**受影响基准图（差异 bbox 已核为相对渐变矩形，旧图把 bug 固化成了一片纯色） |

**只读未动**：`tests/parity/windows/**`、`tests/parity/geometry/**`、`tests/U1-golden/**`、
`upstream/**`、`build/**`、`samples/**`、`handoff.md`、`verify-all.sh`、`port-lib.py`。

**验证状态**：`WpfGfx.Linux.Rendering.Tests` 全量 **81/81 通过**（56 既有 + 25 对照），无跳过。
对照用例全部用 `-m:1` 增量构建运行，未跑整套 `verify-all.sh`。

---

## 8. 复现步骤

```bash
export PATH="$HOME/.dotnet:$PATH"

# 1) 只看对照（数据缺失时发现期跳过）
dotnet test tests/WpfGfx.Linux.Tests/Rendering.Tests/ -m:1 \
  --filter "FullyQualifiedName~ParityTests" --logger "console;verbosity=detailed"

# 2) 看某个场景
dotnet test tests/WpfGfx.Linux.Tests/Rendering.Tests/ -m:1 \
  --filter "FullyQualifiedName~ParityTests.scene13" --logger "console;verbosity=detailed"

# 3) 看差异图
ls tests/parity/linux/diff/          # 红色=超出 AA 容差，必须解释

# 4) 真机数据完整性（采集侧脚本，只读）
python3 tests/parity/windows/verify_u1a_data.py
```

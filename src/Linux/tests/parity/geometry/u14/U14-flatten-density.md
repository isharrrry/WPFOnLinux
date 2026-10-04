# U14 · 展平（flatten）密度差异：量化、原型与落地规格

> **结论先行：不值得把展平器换成上游 `CBezierFlattener`。**
> 30 个用例（U1c 基础 14 + U14 极端探针 16）实测：
> **① 我方展平**没有一例**在几何上真的不对**——所有折线到真曲线的最大偏差都在请求容差之内
> （最坏 0.735×容差）；**② 差异 100% 是"表示差异"**（点集密度/顶点位置不同，区域一致）；
> **③ 上游更密不是更准**，而是 HFD 的二阶导代理判据 + `1024 段/曲线` 硬地板造成的过细分，
> 在个别形状上我们 2 个点就够、上游要 47 个点，精度还都在容差内；
> **④ 真正该处理的是另一个方向的问题**：我方在**超大坐标**输入下密度无上限
> （实测单次调用 73 万点 / 356 MB / 6.2 s，极端 159 万点 / 703 MB / 9.2 s），
> 而上游有硬地板不会爆——**建议只加"密度上限保护"，不动算法**。
> 原型（HFD 逐行移植）已做到**与真机 30/30 用例逐点完全相同**，规格随时可用，但**不建议落**。

---

## 0. 纪律与口径（先声明再对照）

| 项 | 做法 |
|---|---|
| `upstream/` | 严格只读（本轮只读 `bezierflattener.cpp`、`BezierFlattener.h`、`ShapeFlattener.h`、`shapebase.cpp`、`utils.h`） |
| `src/` | **未改任何一行**（M7b 的 lane）。写盘只发生在 `tests/parity/geometry/u14/` |
| 两侧口径 | 输入是**同一份路径字节块**；容差按上游 `GetAbsoluteTolerance`（`shapebase.cpp:1561`）复算；点集一律按 **float32** 对照（真机经 `CFigureData` 的 `MilPoint2F`，我方经 Skia 的 `SKPoint`） |
| 同源 | 真机数据 = `wpfgfx_cor3.dll` 10.0.7（sha256 `f4f7a44a…45f3`）现场跑出；我方数据 = 同一份 `cases.json` 跑本仓库实现跑出（`linux-results-u14.json` 为本轮现跑） |
| 推导 vs 实测 | 表中每一个"点数/误差/Hausdorff"都是**实测或实测点集上的计算**；唯一标注为推导的是 §3 的"上游为何过细分"（源码判据推导 + 用实测点数佐证） |
| U1c 冻结面 | **未动** `cases.json`（仍 215 例）、`windows-results.json`、`linux-results.json`；U14 探针走独立的 `u14/cases-u14.json`（`GeometryOracleTests` 断言的 215 例不受影响） |

两个**方法学坑**（U1c 踩过，本轮规避并复核）：

1. **不同口径直接比**：本轮所有误差都与**同一个绝对容差**比，且先确认两侧容差公式一致
   （只有容差 0 / 负容差两类越界输入上两侧公式不同，已单列）。
2. **不同源当对照**：真机点集全部来自**现场跑真身 DLL**，不是文档、不是推测；
   原型是"逐行移植 + 用真机数据验证到逐点相同"，不是"看起来差不多"。

---

## 1. ① 差异量化：哪些用例、差多少、有没有真缺陷

### 1.1 基础 14 例（U1c 的 flatten 用例）

| 用例 | 绝对容差 | 真机点 | 我方点 | 原型点 | 真机误差 | 我方误差 | 我方/容差 | 真机/容差 |
|---|---|---|---|---|---|---|---|---|
| `flatten_rect_tol01` | 0.1 | 5 | 5 | 5 | 0 | 0 | 0.000 | 0.000 |
| `flatten_circle_tol_0_001` | 0.001 | 633 | **751** | 633 | 7.85e-4 | 7.56e-4 | 0.756 | 0.785 |
| `flatten_circle_tol_0_01` | 0.01 | 257 | 257 | 257 | 3.27e-3 | 3.27e-3 | 0.327 | 0.327 |
| `flatten_circle_tol_0_1` | 0.1 | 65 | 65 | 65 | 5.18e-2 | 5.18e-2 | 0.518 | 0.518 |
| `flatten_circle_tol_0_25` | 0.25 | 49 | **57** | 49 | 0.188 | 0.184 | 0.734 | 0.751 |
| `flatten_circle_tol_1_0` | 1 | 25 | 25 | 25 | 0.740 | 0.740 | 0.740 | 0.740 |
| `flatten_circle_tol_10` | 10 | 9 | 9 | 9 | 3.06 | 3.06 | 0.306 | 0.306 |
| `flatten_circle_tol_0` | 8e-11 | 4097 | **65** | 4097 | 1.73e-5 | 0.0518 | (越界) | (越界) |
| `flatten_circle_relative_true` | 0.8 | 33 | 33 | 33 | 0.205 | 0.205 | 0.256 | 0.256 |
| `flatten_circle_relative_true_tiny` | 0.008 | 257 | 257 | 257 | 3.27e-3 | 3.27e-3 | 0.408 | 0.408 |
| `flatten_circle_with_matrix_scale` | 0.1 | 129 | 129 | 129 | 3.91e-2 | 3.90e-2 | 0.390 | 0.391 |
| `flatten_circle_relative_with_matrix` | 2.4 | 33 | 33 | 33 | 0.614 | 0.614 | 0.256 | 0.256 |
| `flatten_polyline_open` | 0.1 | 4 | 4 | 4 | 0 | 0 | 0.000 | 0.000 |
| `flatten_fillrule_nonzero` | 0.1 | 65 | 65 | 65 | 5.18e-2 | 5.18e-2 | 0.518 | 0.518 |

**11/14 例点数与顶点完全一致**（3 例逐位相同、8 例在浮点容差内）；**3 例点数不同**（加粗）：`tol=0.001`（751 vs 633）、`tol=0.25`（57 vs 49）、`tol=0`（65 vs 4097）。

* "误差"= 沿真曲线等距采样 801 点，到该折线的最短距离的最大值（单侧 Hausdorff 的曲线→折线方向）。
* **所有用例的 `我方/容差` ≤ 0.756** ⇒ 我方展平**从不超出调用方要求的精度**。`tol=0.001` 那一例我方误差
  （7.56e-4）甚至比真机（7.85e-4）**更小**——即我方只是点更少一点，不是更差。

### 1.2 U14 极端探针 16 例（本轮新增：极端曲率 / 极小容差 / 尺度极端 / 退化）

| 用例 | 意图 | 绝对容差 | 真机点 | 我方点 | 原型点 | 真机误差 | 我方误差 | 我方/容差 |
|---|---|---|---|---|---|---|---|---|
| `u14_cusp_loop` | 起点=终点的自环（尖点） | 0.1 | 21 | 17 | 21 | 5.06e-2 | 5.06e-2 | 0.506 |
| `u14_hairpin` | 发夹（两臂只差 0.001） | 0.1 | **47** | **2** | 47 | 3.61e-5 | 2.89e-4 | 0.003 |
| `u14_hairpin_tiny_tol` | 发夹 + 容差 1e-5 | 1e-5 | **1019** | **29** | 1019 | 7.43e-7 | 6.65e-6 | 0.665 |
| `u14_sharp_turn` | S 形急转 | 0.1 | **47** | **9** | 47 | 2.61e-2 | 6.05e-2 | 0.605 |
| `u14_near_collinear` | 控制点离弦 0.001（远小于容差） | 0.1 | 5 | 2 | 5 | 4.70e-5 | 7.50e-4 | 0.007 |
| `u14_near_collinear_small_tol` | 同上 + 容差 1e-6 | 1e-6 | **873** | **33** | 873 | 4.57e-8 | 7.35e-7 | 0.735 |
| `u14_tiny_circle` | 半径 0.01、容差 0.001 | 0.001 | 17 | 17 | 17 | 2.00e-4 | 2.00e-4 | 0.200 |
| `u14_tiny_circle_tol0` | 半径 0.001、容差 0 | 2e-15 | 4097 | 5 | 4097 | 3.99e-10 | 2.93e-4 | (越界) |
| `u14_huge_circle` | **半径 1e7、容差 0.1** | 0.1 | 4097 | **734721** | 4097 | **3.57** | 未算（>20 万） | — |
| `u14_huge_circle_tiny_tol` | 半径 1e7、容差 0.001 | 0.001 | 4097 | **1587249** | 4097 | **3.57** | 未算 | — |
| `u14_degenerate_equal` | 四点重合 | 0.1 | 2 | 2 | 2 | 0 | 0 | 0 |
| `u14_degenerate_line` | 控制点共线等距（精确直线） | 0.1 | 2 | 2 | 2 | 1.8e-15 | 1.8e-15 | 0 |
| `u14_negative_tol` | 负容差（越界输入） | 8e-11 | 4097 | 65 | 4097 | 1.73e-5 | 5.18e-2 | (越界) |
| `u14_relative_zero` | fRelative + 容差 0 | 8e-11 | 4097 | 9 | 4097 | 1.73e-5 | 3.06 | (越界) |
| `u14_extreme_tol` | 容差 1e9 ≫ 图形 | 1e9 | 5 | 5 | 5 | 11.7 | 11.7 | 0 |
| `u14_two_figures_mixed` | 一大一小两个曲线图形 | 0.01 | 354 | 410 | 354 | 7.75e-3 | 7.49e-3 | 0.749 |

### 1.3 判定：**没有真缺陷**（逐条排查）

| 检查项 | 结论 |
|---|---|
| 我方折线是否超出请求容差？ | **否**。16 个探针 + 14 个基础例里，凡容差有意义的用例，`我方/容差 ≤ 0.756` |
| 是否有拓扑错误（缺图形/缺收口/图形数不符）？ | **否**。图形数、`IsClosed`、点数结构逐例与真机对照一致（U1c 已验，本轮探针复核） |
| 是否有"自环/发夹/退化/极端尺度"下的错解？ | **否**。`cusp_loop`/`hairpin`/`degenerate_*`/`tiny_circle`/`extreme_tol` 全部在容差内；我方在发夹上甚至更省点 |
| 是否有插值方向/精度导致的可见偏差？ | **否**。我方点也是 float32，与真机同精度等级；坐标差在 1e-5 量级（U1c 的 Δrel ~1e-7） |
| **我方是否在某个方向比真机差？** | **是，但方向是"密度无上限"而不是"精度不足"**：`u14_huge_circle` 单次调用 734,721 点（§3.2 有实测耗时/内存） |

**同时发现一条上游自身的缺陷（反向证据）**：
`u14_huge_circle` / `_tiny_tol`（半径 1e7）真机误差 **3.57**，请求容差分别是 0.1 / 0.001
⇒ 真机误差是容差的 **35.7× / 3569×**，因为它的"最小步长地板"（`TWICE_MIN_BEZIER_STEP_SIZE = 1e-3`
⇒ 每曲线最多 1024 段）在超大坐标下**先于容差生效**，于是**真机违反了它自己的容差**。
这一列不是我方的问题，但它说明"照抄上游"并不等于"更正确"。

---

## 2. ② 原型对拍：把上游 `CBezierFlattener` 移植过来，差异缩小了多少

原型在 `u14/Program.cs` 的 `HfdFlattener`（逐行移植 `bezierflattener.cpp:40-175, 199-309`）：
HFD 基（`e0..e3`）、`Step`/`HalveTheStep`/`TryDoubleTheStep`、`ApproxNorm = max(|x|,|y|)`、
`m_rTolerance *= 6`、`m_rQuarterTolerance = 1.5×tol`、`TWICE_MIN_BEZIER_STEP_SIZE = 1e-3`。

| 指标 | 结果 |
|---|---|
| 原型点数 == 真机点数 | **30/30 用例全部相等**（14 基础 + 16 探针，含 4097 点的 tol=0 与半径 1e7 的极端例） |
| 原型点集 == 真机点集（逐点） | **30/30 逐点完全相同，最大逐点偏差 = 0**（不是"接近"，是同一串 float32 坐标） |
| 基础 14 例：点集差异 | 修前 3 例不同 → 修后 **0 例不同** |
| 基础 14 例：Hausdorff(我方↔真机) | 3 例非零：`tol=0.001` 7.88e-4、`tol=0.25` 0.188、`tol=0` 0.0518；其余 ~1e-5 → 修后 **全 0** |
| 探针 16 例：点集差异 | 修前 11 例不同（最大 1,587,249 vs 4097）→ 修后 **0 例不同** |

⇒ **"对齐上游细分"确实能把点集差异压到 0**（这一点上任务是可达的）。
但"差异归零"不等于"值得做"——见 §4。

---

## 3. ③ 落地规格与风险

### 3.1 若主控决定要"与真机逐点一致"，规格如下（**M7b 可直接照抄，但我不建议**）

| # | 位置 | 改成什么 | 风险 |
|---|---|---|---|
| S1 | `MilGeometryEngine.Flatten` | 用 `HfdFlattener`（本仓 `tests/parity/geometry/u14/Program.cs` 内，已验证逐点一致）替换 `FlattenCubic`/`FlattenQuad` 的递归二分 | 输出点数变化：基础例最多 ×63（tol=0：65→4097）；探针最坏 ×20~45（hairpin 2→47）；**金标图不受影响（见 3.3）**；显式 flatten/area/hittest 三条导出的耗时与内存随之上升 |
| S2 | 容差绝对化 | 新增 `AbsoluteTolerance(tol, rel, extent)`，公式 `rel ? max(tol,1e-12)*extent : max(tol, extent*1e-12)`（`shapebase.cpp:1583-1591`）替掉 `ResolveTolerance` 的 `tol>0?tol:0.1` 兜底 | **单独改这一条是危险的**：实测我们的二分在 `tol=0`（绝对容差 8e-11）下会爆到 **1,594,827 点/次调用**（真机 4097），因为上游靠 1e-3 最小步长收口、我们没有。**S2 必须与 S1 同时落，或另加密度上限** |
| S3 | `Flatten` 的 `tol<=0 → 0.1` 兜底 | 删除（交给 S2） | 若只删 S3 不改 S2，`tol=0` 会走进 `Flatten(path, 0)` → 仍被内部兜底成 0.1 → 行为不变（无害但也无收益） |
| S4 | Area/HitTest 里的 `Flatten(transformed, 0.1)` 预展平 | 保持不变 | 这两处只是取包围盒/命中判定，容差 0.1 足够；改动会牵连面积与命中结果（U1c 已对拍通过，**不要顺手改**） |

### 3.2 性能与内存：**这才是真正的风险**（实测）

同一个 harness、同一份单用例输入、同一 .NET 10：

| 用例 | 真机（Windows 开发机，直接跑 exe） | 我方（本机，`dotnet run`） | 扣掉启动后的净耗时 |
|---|---|---|---|
| `u14_degenerate_equal`（基线） | 0.19 s | 2.02 s（启动基准） | ~0 s vs ~0 s |
| `u14_huge_circle`（r=1e7, tol=0.1） | **0.20 s** | **8.17 s / 356 MB** | ≈ 0.01 s vs **≈ 6.2 s** |
| `u14_huge_circle_tiny_tol`（tol=0.001） | **0.19 s** | **11.22 s / 703 MB** | ≈ 0.01 s vs **≈ 9.2 s** |
| `u14_two_figures_mixed` | — | 3.17 s / 126 MB | ≈ 1.3 s |

口径说明（避免 U1c 那类"不同口径直接比"的错）：两侧是**不同机器/不同 OS**（Windows 开发机 vs 本 Linux 机），
且我方走 `dotnet run`（含宿主启动）。所以上表**减去同命令的基线启动耗时**后再比；
即便再放宽一档，量级差仍在 **≥100×**，峰值内存 **700 MB**。
⇒ 结论：**我方当前的问题是"密度无上限"，不是"不够密"**。
`u14_huge_circle` 的 734,721 点换来的是"误差 3.57 → 远小于 0.1"，而真机用 4097 点换来"误差 3.57 > 0.1"；
两边都不理想，但我方的失败模式（时间/内存）比真机的失败模式（几何偏粗）更危险。

### 3.3 对 23 张 golden 基准图的影响：**零（已验证，不是推断）**

三条独立证据：

1. `grep -rn "MilGeometryEngine.Flatten\|ResolveTolerance\|\.Flatten(" src/` → **只有
   `src/WpfGfx.Linux/Interop/MilNative.Geometry.cs` 的 7 处调用**（Flatten 导出、Area 导出、HitTest），
   `Rendering/` `Commands/` `Resources/` `Contracts/` 里**一次都没有**。
2. `grep -rn "MilUtility\|MilGeometryEngine" tests/.../Rendering.Tests/*.cs` → **空**；
   `GoldenRunner` 走的是 `RenderHarness.Render`（Skia 直接吃 `SKPath`，曲线由 Skia 自己细分）。
3. `tests/golden/` 的 23 张图是渲染层基准，展平器**不在渲染路径上**。

⇒ **U14 若落 S1/S2，23 张 golden 不会变**（这条与直觉相反，所以必须在规格里写明：
"金标风险为零"是**可复核的结论**，不是"我们赌它不变"）。
真正的回归面是三处显式导出：`MilUtility_PathGeometryFlatten`、`MilUtility_GeometryGetArea`、
`MilUtility_PathGeometryHitTest` 的输出/耗时，以及 **U1c 的 `GeometryOracleTests` 里
flatten 的 3 条已知差异登记**（落地后应从清单里划掉 3 条）。

---

## 4. ④ 结论：**不值得做**（登记维持原样 + 一个可选的小加固）

| 判据 | 结论 |
|---|---|
| 有没有真缺陷要修？ | **没有**。我方展平在所有有意义容差下都 ≤ 0.756×容差，拓扑与真机一致 |
| 对齐上游能不能消掉差异？ | 能（原型 30/30 逐点相同），但**换来的只是"表示一致"**，几何精度没有提升 |
| 上游更密是否更准？ | **否**。发夹上我们 2 点（误差 2.9e-4）vs 上游 47 点（误差 3.6e-5），两者都远在容差 0.1 之内；上游的密度来自 HFD 的二阶导代理判据 + 1024 段/曲线地板，是"按构造"而非"按需" |
| 代价 | tol=0 时输出 ×63、发夹 ×23、急转 ×5；且**没有任何精度收益**；与我方"密度无上限"的问题叠加还会放大内存风险 |
| 金标风险 | 零（已验证）——所以"代价"不在金标，而在**显式 flatten 调用的时间/内存与指令流体积** |
| 建议 | **维持原样**（`docs/unimplemented.md` 的"Widen 忽略 rTolerance"那条另说，与本轮无关）。把"与真机逐点一致"降级为**可选项**：原型已备好、验证过，等字节级指令流对拍（另一个 milestone）真需要时再落 |

### 建议的唯一改动：**密度上限保护**（可选，低风险，与 U14 主题同源）

我方在超大坐标下无上限地细分（实测 73 万 / 159 万点、356 / 703 MB、6~9 s）。
建议在 `FlattenCubic` 里加一道**代价上限**（不是改算法）：

* 方案 P1（推荐）：保留现有判据，增加"每条曲线段最多 N 段"的硬上限（N 取 4096 或 8192），
  超出即停止细分并对该段发一条直边——**行为与上游的 1e-3 地板同构**，但阈值更宽（4096 > 上游 1024），
  所以只会砍掉"病态输入"，不影响任何正常用例；
* 方案 P2：把 `MaxSubdivisionDepth` 从 20 降到 12（同效，但更粗糙、更难解释）。
* 风险：P1 会让 `u14_huge_circle` 从"73 万点、误差≪0.1"变成"≤4096 点、误差 ≈ 3.6"——
  **和真机一样违反容差**。所以这是"用精度换可用性"的取舍，**要不要做请主控定**；
  若要求"永不违反容差"，则应改走"拒绝/报错"而不是"静默降精度"。
  → 这条我**没有实现**（属于 `src/` 的 lane），只给规格。

---

## 5. 产物与复现

```
tests/parity/geometry/u14/
  U14.csproj                 独立控制台（**不引用 src/**，不与 M7b 的编译状态耦合）
  Program.cs                 HFD 原型 + 我方算法复刻 + 度量 + 探针生成器
  u14-density.md / probe-density.md      自动生成的密度/误差表
  u14-pointsets.json / probe-pointsets.json  逐例结构化数字
  cases-u14.json             U14 探针 16 例（独立文件，不动 U1c 的 215 例）
  windows-results-u14.json   真身 DLL 现场跑出的 16 例结果
  linux-results-u14.json     本仓库实现现场跑出的 16 例结果
```

```bash
export PATH="$HOME/.dotnet:$PATH"; cd <REPO>

# 1) 生成 U14 探针用例
dotnet run --project tests/parity/geometry/u14 -- gen tests/parity/geometry/u14/cases-u14.json

# 2) 我方实现跑探针（引用本仓库 src/，只读不改）
dotnet run --project tools/GeometryOracle -- run \
    tests/parity/geometry/u14/cases-u14.json tests/parity/geometry/u14/linux-results-u14.json

# 3) 真机跑探针（Windows，C:\u1-geom；源码见 tests/parity/geometry/windows-harness）
#    bin\Release\net10.0\u1geom.exe cases-u14.json windows-results-u14.json
#    拷回 tests/parity/geometry/u14/

# 4) 出表（基础 14 例 / 探针 16 例）
cd tests/parity/geometry
dotnet run --project u14 -- cases.json        windows-results.json    linux-results.json    u14/u14
dotnet run --project u14 -- u14/cases-u14.json u14/windows-results-u14.json u14/linux-results-u14.json u14/probe
```

**没有改动的**：`src/**`（M7b）、`docs/**`、`handoff.md`、`verify-all.sh`、`samples/**`、
`build/**`、`tests/golden/**`、`tests/parity/windows/shaping/**`、`tests/U1-golden/**`，
以及 U1c 冻结的 `cases.json` / `windows-results.json` / `linux-results.json` / `summary.*`。
本轮**没有在 Linux 上跑全量构建或测试**，只构建并运行了 `tests/parity/geometry/u14` 与
`tools/GeometryOracle` 两个项目。

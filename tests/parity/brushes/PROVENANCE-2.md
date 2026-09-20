# TileBrush 真机 oracle —— 批次 2（按实现缺口排序）

> 批次 1（TileMode 五档 × 两源 × 三档 Viewport，74 例）见同目录 `PROVENANCE.md`
> 与 `windows-results.json`；**本文件只讲批次 2**，产物是
> `windows-results-2.json` + `cases-2.json` + `out/b2_*.png`（60 张）。批次 1 的文件未被覆盖。
>
> 采集环境与批次 1 完全相同（同一台 Windows、同一份 `wpfgfx_cor3.dll`、
> 96 DPI 基线、session 0），见 `windows-results-2.json` 的 `environment`。
> 正常跑 **60/60 用例通过、`failures=0`、退出码 0**；破坏性自检 **`failures=32`、退出码 2**。

## 批次 2 用例矩阵（60 例）

| 家族 | 数量 | 覆盖 | 优先级依据 |
|---|---:|---|---|
| `gap` | 19 | **`Stretch=None` × `AlignmentX/Y`(Left/Top, Center, Right/Bottom) × `TileMode` 五档**，v2tiling；另加 v1same 的单格基线 | **已知缺口**，最高优先 |
| `scaling` | 16 | `BitmapScalingMode`{NearestNeighbor, Linear, HighQuality, Unspecified} × {放大 2.5×1.5, 缩小 0.375×} × {ImageBrush, DrawingBrush} | 先确认它到底改不改变像素 |
| `dpi` | 18 | DPI {96,120,144} × {image Tile/FlipX, drawing, visual, v1same} **+ DPI × `Stretch=None`**（唯一 DPI 敏感的一档） | 非 96 DPI |
| `textmode` | 4 | `TextFormattingMode`{Ideal, Display} × TileMode{Tile, FlipX}，VisualBrush + TextBlock | 含文字瓦片 |
| `cachebrush` | 3 | `BitmapCacheBrush` 探针：无缓存 / 默认 `BitmapCache` / `RenderAtScale=2` | **先判"在不在范围内"** |

---

## 1. `Stretch=None` × `Alignment` × `Flip*`（已知缺口）—— 结案

**问题**：`Stretch=None` 时源不缩放，32×32 的图贴在 80×48 的瓦片里；那么 `FlipX` 到底是
（a）**整格镜像**（连"图贴在哪儿"一起翻，图跳到瓦片另一侧）还是（b）**只镜像图像本身**（图还在原地）？

**答案：(a) 整格镜像，连放置位置一起翻。** 证据是从 PNG 直接量的墨迹范围
（`Alignment=Left/Top`，瓦片 80×48 @(16,16)，图像 32×32；下面是**瓦片内**的相对坐标）：

| 用例 | 观察的瓦片 | 墨迹位置（瓦片内） | 距左缘 | 距右缘 | 距上缘 | 距下缘 |
|---|---|---|---:|---:|---:|---:|
| `b2_gap_none_left_tile_v2tiling` | tile(1,0) | x∈[97,127] | **1** | 48 | 1 | 16 |
| `b2_gap_none_left_flipx_v2tiling` | tile(1,0) | x∈[144,174] | **48** | **1** | 1 | 16 |
| `b2_gap_none_left_flipy_v2tiling` | tile(0,1) | y∈[80,110] | 1 | 48 | **16** | **1** |
| `b2_gap_none_left_flipxy_v2tiling` | tile(1,1) | x∈[144,174] y∈[80,110] | 48 | 1 | 16 | 1 |

⇒ 未翻转的瓦片里图像贴身左上（距左/上 1px），水平翻转后**跑到瓦片右侧**（距右 1px、距左 48px）。
"只镜像图像、位置不动"会得到 x 仍在 [97,127]，**与实测不符**。

**独立模型复核**：我把"整格镜像（含放置）"写成一个源空间模型（`PredictedStretchNone`），
在 **19 个 gap 用例上全部逐点 100% 吻合**（358/358、355/355、363/363、357/357、393/393、
389/389、392/392、387/387、405/405、410/410、403/403、406/406、389/389、386/386 …）。
即这套语义可以照抄：**先按 Alignment 在瓦片内放好图，再对整个瓦片做镜像**。

补充事实（同批实测）：`Stretch=None` 时瓦片内**其余区域是空的**（背景透出来），
且 `TileMode=None` 仍然只画基准格（`b2_gap_none_*_none_v2tiling` 的已画采样点只有 16–19 个）。

---

## 2. `BitmapScalingMode` —— **它确实改变像素**（不是"三档全同"的负结果）

对比是在**固定采样网格**上逐点数的（同组内只有这一个维度不同）：

| 源 / 缩放 | NearestNeighbor vs Linear | NN vs HighQuality | Linear vs HighQuality | Linear vs Unspecified | HighQuality vs Unspecified |
|---|---:|---:|---:|---:|---:|
| ImageBrush 放大（32→80×48） | **68** | **68** | 0（相同） | 0（相同） | 0（相同） |
| ImageBrush 缩小（32→12×7.2） | **187** | **414** | **409** | 0（相同） | **409** |
| DrawingBrush 放大 | 0 | 0 | 0 | 0 | 0 |
| DrawingBrush 缩小 | **308** | **308** | 0 | 0 | 0 |

结论（可直接写进实现）：
1. **`Unspecified` ≡ `Linear`**（放大、缩小、位图、矢量四种组合下都是 0 差异）⇒
   我们的默认路径按 Linear 实现即可。
2. **`HighQuality` 只在"缩小"时才与 Linear 不同**（ImageBrush 缩小时差 409 点；放大时完全相同）。
   换句话说 HighQuality 的额外价值是**缩小过滤**（盒式/多级），放大时退化成 Linear。
3. **`NearestNeighbor` 与其它三档一律不同**（放大 68、缩小 187–414）⇒ 必须真的实现最近邻。
4. 矢量源（DrawingBrush）放大时四档**完全一致**（0 差异，符合预期）；缩小时只有 NearestNeighbor
   不同 —— 说明矢量路径下 `BitmapScalingMode` 只影响"是否对矢量做点采样式降采样"。

---

## 3. 非 96 DPI（120 / 144）

**关键设计**：把**设备空间几何固定住**（画布 = 256/scale DIU、目标矩形同样按 scale 折算），
于是设备像素网格、瓦片尺寸、目标矩形在三个 DPI 下完全一致，**只有 DPI 语义本身**在变。

| 对比 | 结果 |
|---|---|
| 核心矩阵（ImageBrush/DrawingBrush/VisualBrush，Tile/FlipX/None，96 vs 144） | **逐点完全相同（0 差异）** |
| 同上，96 vs 120 | 差 2 个采样点 |
| 同上，120 vs 144 | 差 8–9 个采样点 |
| 含文字瓦片（VisualBrush + TextBlock，`TextFormattingMode=Ideal`） | 与上面同量级（96 vs 120 差 2 点） |
| **`Stretch=None`（图像自然尺寸）** | **显著不同，见下** |

⇒ 结论一：`Viewport` 用相对单位、`Viewbox` 用绝对（源单位）时，**瓦片语义与渲染 DPI 无关**；
剩下那 0–9 个点的差异是 **DIU→设备像素落在分数坐标上的 AA 取整**（120 DPI 时画布宽
256/1.25 = 204.8 DIU，144 DPI 时 170.667 DIU，都是非整数）。
⇒ 结论二：`TextFormattingMode=Ideal` 的文字**也是 DPI 无关的**（Ideal 的定义就是与分辨率无关），
所以本批没有观察到"Ideal 文字随 DPI 变化"。

⇒ 结论三（**唯一 DPI 敏感的一档**）：`Stretch=None` 时源按**自然尺寸**绘制，此时位图自带的
96 DPI 会被渲染 DPI 乘进去。实测墨迹边长（tile(0,0) 内，直接从 PNG 量）：

| DPI | scale | 期望边长 32×scale | 实测边长 |
|---|---:|---:|---:|
| 96 | 1.000 | 32 | **31**（含 1px 背景缝隙，等价于 32） |
| 120 | 1.250 | 40 | **40** ✓ |
| 144 | 1.500 | 48 | **48** ✓ |

模型（把 32×scale 写进几何）在 120 DPI 上 **355/355**、144 DPI 上 **384/386** 吻合
（144 DPI 那 2 个失配点是分数设备坐标下角上的取整，见 §6 的已知限制）。
⇒ 实现要求：`Stretch=None` 时**必须**用 `位图固有 DPI × 渲染 DPI` 决定自然尺寸；
其余档位（`Viewbox` 覆盖整幅 + `Stretch=Fill`）与位图 DPI 无关。

---

## 4. `TextFormattingMode`（Ideal vs Display）

含文字瓦片（VisualBrush + TextBlock "F7"）实测：**Tile 档差 20 个采样点、FlipX 档差 20 个采样点**
（`b2_text_ideal_*` vs `b2_text_display_*`）⇒ **96 DPI 下 Display 确实改变像素**（像素对齐/提示），
差异全部集中在文字区域（模型把文字区标为"未知"，因此两边都保持 183/183 满分）。
⇒ 实现上 `Ideal`（默认）必须与 `Display` 分开走：Ideal 用与分辨率无关的字形轮廓，
Display 走像素吸附/提示式光栅化。

---

## 5. `BitmapCacheBrush`：**在不在范围内 → 不在（建议划掉）**

按"先给判定、别先铺用例"的要求，只做了 **3 个探针用例**，结论却很清楚：

| 判据 | 实测 / 证据 |
|---|---|
| **是不是 `TileBrush`？** | **不是**。`brushTypeUsed = BitmapCacheBrush`、`isTileBrush = false`。它直接继承 `Brush`，**没有** `Viewport/Viewbox/Stretch/AlignmentX/Y/TileMode` 这些属性 |
| ⇒ 对本项目意味着什么 | 我们 `SkiaBrush` 的 TileBrush 旋钮矩阵（批次 1/2 的全部内容）**对 BitmapCacheBrush 根本不适用**，不存在"TileMode=FlipX 该怎么画"的问题 |
| 与 VisualBrush 的像素关系 | 差 369/444 采样点（因为它把视觉**铺满整个矩形**而不是平铺） |
| 默认 `BitmapCache` 有没有改变像素 | **没有**：`nocache` vs `cache` = **0/444 不同** ⇒ 软件 `RenderTargetBitmap` 下默认缓存是纯性能优化 |
| `BitmapCache.RenderAtScale=2` | **有**：与默认缓存差 **67/444** ⇒ 缓存分辨率是可观测的 |
| 上游依据 | `BitmapCacheBrush : Brush, ICyclicBrush`（上游注释："This class is basically identical to VisualBrush"）；命令 `MilCmdBitmapCacheBrush(0x84)`、`MilCmdBitmapCache(0x8d)` 存在，我方 `MilCommandLayout.cs:116/136` 也已登记长度 |

**建议**：把 `BitmapCacheBrush` **划出 TileBrush 验收范围**。理由：① 它不是 TileBrush，
本项目的 TileBrush 矩阵与它无关；② 它的"缓存"语义在软件渲染下默认不可观测，只有
`RenderAtScale` 才可观测，属于**缓存/效果**轨道的问题；③ 若将来要做，应按"缓存轨道"
单独立项（含 `RenderAtScale`、`EnableClearType`、`SnapsToDevicePixels` 与硬件/软件差异），
本批这 3 个探针只作为"不在范围内"的判据保留，**不是功能用例**。

---

## 6. 防假绿与"我自己的 bug"（这一节比结论重要）

| 机制 | 结果 |
|---|---|
| 每例非纯色 / 目标确实被画 | 60/60 通过 |
| 同组只差 TileMode 的用例必须两两不同 | 37 条对比全过（19 个 gap 用例贡献了主要判别力） |
| 比较器自检（自己 vs 自己必须相同） | ok |
| **破坏性自检** `--batch2 --sabotage`（Flip* 全按 Tile 渲染） | **`failures=32`、退出码 2** |

**期间被这套纪律抓出来的、我自己写错的三处**（都已在代码里修掉）：

1. **分组键漏了新维度** ⇒ 把"只差 DPI / 只差 BitmapScalingMode"的用例也塞进同一组，
   于是"Tile vs Tile 必须不同"的断言误报 **19 条**。修法：分组键必须包含**除 TileMode 以外
   的全部轴**（Family/Source/Viewport/Viewbox/Stretch/Alignment/Target/Dpi/BitmapScalingMode/
   TextFormattingMode/BitmapCacheMode）。
2. **`Stretch=None` 时模型压根没跑**：`TileGeometry()` 对非 `Fill` 一律返回 `Known=false`，
   导致 gap 家族 19 例全是 `model=0/0`（看起来"全绿"，其实一条模型断言都没执行）。
   修法：`Fill` 与 `None` 都要算瓦片几何（两者只差瓦片内的放置方式）。
3. **`nocache` 探针其实建的是 VisualBrush**：我把"无缓存"标成 `null`，而 `null` 在那个分支里
   意味着"不是缓存画刷"，于是它走了 VisualBrush 路径（`isTileBrush=true`，"与 VisualBrush
   完全相同"是恒真的废话）。修法：用 `"none"` 显式表示"BitmapCacheBrush 但不设 BitmapCache"，
   并**新增 `brushTypeUsed` 字段**把实际构造出来的画刷类型写进结果——这条字段就是为防这类
   标签错误加的。

**已知限制（如实记录）**：
- `variantComparisons` 的差异计数是在**固定采样网格**上数的。对 DPI 那一档，图像足迹变化
  （32→40→48 px）可能落在网格点之间 ⇒ **96 vs 120 只数出 2 个差异点**，而直接量 PNG 的墨迹
  足迹是 40×40。**决定性证据是 PNG 足迹测量，不是那两个计数**。
- 5 个"缩小"用例（`b2_scale_down_*`）的模型吻合度不是满分（128/204、166/204 等）：
  我的模型做的是**点采样**，而缩小 0.375× 时每个设备像素覆盖多个源texel，WPF 在平均
  ⇒ 这是**模型的局限**（已按"点采样不适用"解释），不是 WPF 行为异常。
- 144 DPI 的 `Stretch=None` 用例 384/386：2 个失配在角上，源于分数设备坐标
  （画布 170.667 DIU）的取整，同样是模型用整数瓦片几何近似的局限。

---

## 7. 文件清单（批次 2 追加，批次 1 未被覆盖）

| 路径 | 说明 |
|---|---|
| `cases-2.json` | 批次 2 的 60 个用例规格 |
| `windows-results-2.json` | 批次 2 结果：环境、逐用例元数据 + 采样点、`discrimination`（37 条）、`variantComparisons`（跨档对比 29+ 条） |
| `out/b2_*.png` | 批次 2 的 60 张真机 PNG（Bgra32 直通 alpha，96/120/144 DPI） |
| `out/run-normal-batch2.log` | 正常采集（`cases=60 failures=0`，RC=0） |
| `out/run-sabotage-batch2.log` | 破坏性自检（`failures=32`，RC=2） |
| `src/` | 采集程序源码（批次 2 已扩展：新增 `gap`/`scaling`/`dpi`/`textmode`/`cachebrush` 五个家族与 `Stretch=None` 模型） |
| `PROVENANCE.md` | 批次 1 的说明（含通用环境/复现命令/批次 1 结论） |

复现命令（Windows 侧）：

```cmd
cd /d C:\wpf-oracle-brush\src\U1BrushOracle
dotnet build -c Release -v q --nologo
:: 批次 2 正常采集
cmd /v:on /c "bin\Release\net10.0-windows\U1BrushOracle.exe C:\wpf-oracle-brush\out2 --batch2 & echo RC=!errorlevel!"
:: 批次 2 破坏性自检
cmd /v:on /c "bin\Release\net10.0-windows\U1BrushOracle.exe C:\wpf-oracle-brush\out2-sabotage --batch2 --sabotage & echo RC=!errorlevel!"
```

## 8. 仍未覆盖（批次 2 之后）

- `Stretch=Uniform`/`UniformToFill` × `TileMode=Flip*`（批次 2 只做了 `Fill` 与 `None`；
  这两档会 letterbox，瓦片内会留边，与 Flip 的组合没测）。
- `Viewbox` 取子区域（非整幅）× `Stretch=None` 的组合。
- `BitmapScalingMode` 在 120/144 DPI 下的表现（只测了 96 DPI）。
- `BitmapCacheBrush` 的 `EnableClearType` / `SnapsToDevicePixels`（按建议划出范围，未测）。
- `Stretch=None` + 非 96 DPI + **Flip** 的组合（只测了 Tile）。

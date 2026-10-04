# TileBrush 真机像素 oracle（Windows WPF）

> ℹ️ **批次 2（按实现缺口排序：`Stretch=None`×Flip、`BitmapScalingMode`、120/144 DPI、
> `TextFormattingMode=Display`、`BitmapCacheBrush` 范围判定）见同目录 `PROVENANCE-2.md`，
> 产物是 `windows-results-2.json` / `cases-2.json` / `out/b2_*.png`。批次 1 的文件未被覆盖。

> **这批数据的用途**：把 Linux 侧 `SkiaBrush.cs` 里 `DrawingBrush`/`BitmapBrush` 的
> `TileMode = FlipX/FlipY` 从"锁进 golden 的近似值"变成**钉死的真值**。
> 原来那个 golden 记的是我们的实现，不是 WPF 的行为；本目录里的每一张 PNG 都是
> 真机 `RenderTargetBitmap` 的输出，且**每个用例都带一个能证明它有区分力的像素点**
> （见 §5）——对称源会让 `Tile` 与 `FlipX` 逐像素相同，从而"看起来通过而实际没验证"，
> 本批次从源图案设计上就避免了这一点。

- 真机数据目录：`tests/parity/brushes/`（本目录）
- Windows 工作目录：`C:\wpf-oracle-brush\`（另一个 agent 用 `C:\wpf-oracle-layout\`，互不相干）
- 采集程序源码：`src/`（`U1BrushOracle.csproj` + 4 个 `.cs`）
- 用例规格：`cases.json`；结果：`windows-results.json`；渲染结果：`out/*.png`

---

## 1. 环境留痕

| 项 | 值 |
|---|---|
| 机器 | `Bilintu`（Windows 10.0.22631，x64，8 核） |
| 会话 | **SessionId = 0**，`UserInteractive = False`（无桌面会话，与 U1a 采集同条件） |
| .NET SDK | `dotnet --version` = **10.0.203** |
| 运行时 | `Microsoft.WindowsDesktop.App 10.0.7` |
| `PresentationCore.dll` | 文件版本 **10.0.726.21808**，SHA256 见 `windows-results.json` 的 `environment` |
| `wpfgfx_cor3.dll` | **10,0,726,21808 @Commit: b16286c2284fecf303dbc12a0bb152476d662e44**（与 U1a `probe.json` **同一份二进制**） |
| 渲染目标 | `RenderTargetBitmap(256,256,96,96,PixelFormats.Pbgra32)`，包在一个 `Canvas` 上 |
| **DPI** | **只用 96**；每个用例 dump `dpiX/dpiY`（=96）与 `VisualTreeHelper.GetDpi().PixelsPerDip`（=1.0） |
| 像素格式 | PNG 为 **Bgra32 直通 alpha**（`FormatConvertedBitmap(Pbgra32 → Bgra32)`），`A` 通道一并 dump |
| `TextFormattingMode` | `Ideal`（每个用例 dump `layout.textFormattingMode`） |
| 位图缩放模式 | `layout.bitmapScalingMode`（元素未显式设置 = `Unspecified`，ImageBrush 实际走双线性） |
| 画布背景 | 不透明档 `#FF808080`；alpha 档无背景（`#00000000`），用于暴露直通/预乘歧义 |

命令留痕：`dotnet --version` → `10.0.203`；构建 `dotnet build -c Release`（0 警告 0 错误）。

---

## 2. 复现命令（全在 Windows 上，Linux 侧零构建）

```cmd
:: 1) 建目录 + 传源码（Linux → Windows）
mkdir C:\wpf-oracle-brush\src\U1BrushOracle
scp tests/parity/brushes/src/*  PC@192.168.193.97:C:/wpf-oracle-brush/src/U1BrushOracle/

:: 2) 构建
cd /d C:\wpf-oracle-brush\src\U1BrushOracle
dotnet build -c Release -v q --nologo

:: 3) 正常采集（74 个用例 → PNG + samples + 元数据 + 自检）
C:\wpf-oracle-brush\src\U1BrushOracle\bin\Release\net10.0-windows\U1BrushOracle.exe C:\wpf-oracle-brush\out

:: 4) 【防假绿】破坏性自检：把 FlipX/FlipY/FlipXY 全部按 TileMode.Tile 渲染，
::    判别力断言必须变红、进程必须退出码 2
cmd /v:on /c "U1BrushOracle.exe C:\wpf-oracle-brush\out-sabotage --sabotage & echo RC=!errorlevel!"

:: 5) 取回
scp "PC@192.168.193.97:C:/wpf-oracle-brush/out/*" tests/parity/brushes/out/
```

非破坏性：只写 `C:\wpf-oracle-brush\`；未改系统设置、未装字体、未写注册表、未碰 `C:\Windows`。

---

## 3. 用例矩阵（74 个用例，`cases.json` 是唯一真源）

| 家族 | 数量 | 覆盖 |
|---|---:|---|
| **core**（批次 1） | **30** | `TileMode` × {`None`,`Tile`,`FlipX`,`FlipY`,`FlipXY`} × 源 {`ImageBrush`,`DrawingBrush`} × `Viewport` {v1same, v2tiling, v3offset} |
| visual | 15 | 同矩阵，源换 `VisualBrush`（含 `TextBlock "F7"`） |
| stretch | 16 | `Stretch` {None,Uniform,UniformToFill,Fill} × `Alignment` {Left/Top, Center/Center} × {单 tile, v2tiling+Tile} |
| units | 5 | `ViewportUnits`/`ViewboxUnits` 绝对/相对混用、`Viewbox` 取子区域（2× 放大） |
| fractional | 4 | 目标矩形 `(13.5, 9.25, 183.5, 117.25)`：非整数位置/尺寸 |
| alpha | 4 | 半透明源（50%/25%/75%）× {不透明背景, 透明背景} × {Tile, FlipX/FlipY} |

三档 `Viewport` 的定义（`RelativeToBoundingBox`，目标矩形 `(16,16,200,120)`）：

| 名称 | Viewport | 实际瓦片 | 含义 |
|---|---|---|---|
| `v1same` | `(0,0,1,1)` | 200×120 @ (16,16)，**只有一格** | 基线：不触发平铺 |
| `v2tiling` | `(0,0,0.4,0.4)` | 80×48，目标 = 2.5×2.5 格 | 平铺 + 末端半格 |
| `v3offset` | `(0.3,0.2,0.4,0.4)` | 80×48 @ (76,40) | **平铺原点带偏移**（最易搞错的一档） |

---

## 4. 防假绿（anti-false-green）与它被现场推翻的证据

每个用例都要过这几条断言，**任一条不成立就整份结果不成立**：

| # | 断言 | 本次结果 |
|---|---|---|
| 1 | PNG 不是纯色（采样到的不同颜色 ≥3） | 74/74 通过（最少 5 色） |
| 2 | 目标区域确实被画了（判别采样点 ≠ 背景） | 74/74 通过（最少 16 个已画点） |
| 3 | **平铺档里 Tile / FlipX / FlipY / FlipXY 两两必须不同**（同组其它参数完全相同） | **93/93 组对比全过**；`FlipX vs Tile` 差异采样点 122–162，`FlipXY vs Tile` 215–269 |
| 4 | 单格档（`v1same`）五档在**内部**（离目标边 ≥8px）必须完全相同 | 74 个对比全过 —— 这本身是一条被断言的 WPF 事实（单格时看不见翻转） |
| 5 | 比较器自检：同一用例与自己比必须判"相同" | `selfTest = ok` |
| 6 | **破坏性自检**：`--sabotage` 把 Flip* 全按 Tile 渲染 | **51 条断言变红、退出码 = 2**（见 `out/run-sabotage.log`，39 条 `NO DISCRIMINATION`） |

破坏性自检的真实输出（`out/run-sabotage.log`）：

```
cases=74 failures=51 sabotage=True selfTest=ok
  ! NO DISCRIMINATION: core|image|v2tiling|v[0,0,0.4,0.4]|RelativeToBoundingBox|stretch=Fill|align=Center/Center
      Tile vs FlipX are pixel-identical at all 444 samples - this case cannot tell them apart
  ...
SABOTAGE_RC=2          <- Linux 侧 ssh 捕获（cmd /v:on /c "... & echo RC=!errorlevel!"）
NORMAL_RC=0            <- 正常采集
```

即：**这套断言不是"我加了个断言"，而是被一个已知真值现场推翻过**——
把 `TileMode` 写错，它立刻红并且拒绝产出结果文件。

---

## 5. 每个用例的判别点及其理由（本批次最关键的一节）

### 5.1 源图案为什么必须不对称

`Tile` 与 `FlipX` 在**对称源**上逐像素相同 → 用例会"绿着什么都没证明"。
本批次两种图形源（`ImageBrush` 的 32×32 位图与 `DrawingBrush` 的矢量图）用**同一套几何**
（像素级一致，便于交叉对照），刻意做成：

```
  32×32 连续坐标系（x/y 是左上角，w/h 右开）
  ┌───────────────┬───────────────┐
  │ 红 #D02020    │ 品红条(左,竖直)│ 绿 #20A040     │   ← 四角四色、互不相同
  │               │ #FF00FF x2..6 │                │
  ├───────────────┴───────────────┤                │
  │       青条(上,水平) #00FFFF   │                │
  │       y2..6 / x10..20         │                │
  │                               │                │
  ├───────────────┬───────────────┼───────────────┤
  │ 蓝 #2050D0    │ 紫三角(直角在左上) │ 黄 #E0C020   │
  └───────────────┴───────────────┴───────────────┘
   底/中缝：#202830（深灰蓝）
```

- **品红条只在左边**（x∈[2,6)，y∈[10,20)）⇒ 水平翻转会把它搬到右边
- **青条只在上边**（x∈[10,20)，y∈[2,6)）⇒ 垂直翻转会把它搬到底部
- 四角四色 + 偏心白点 + 直角在左上的紫三角 ⇒ 任何镜像都会改变至少一个具名像素

### 5.2 判别点是怎么算的、放在哪里

程序按瓦片几何把源坐标映射到设备像素：
`device = tileOrigin + tileIndex*tileSize + (source/32)*tileSize`。
**基准格（index 0）永远不翻转**，所以判别点一律取 **index 1** 的那一格
（每个平铺档都至少产生 tile 1）。四个具名判别点：

| 具名点 | 源坐标 | 未翻转时的颜色 | 翻转后 |
|---|---|---|---|
| `mag-left` | (4.5, 15.5) | `#FFFF00FF` 品红 | 变成底色 `#FF202830` |
| `mag-right` | (27.5, 15.5) | `#FF202830` 底色 | 变成品红 `#FFFF00FF` |
| `cyan-top` | (15.5, 4.5) | `#FF00FFFF` 青 | 变成底色 |
| `cyan-bot` | (15.5, 27.5) | `#FF202830` 底色 | 变成青 `#FF00FFFF` |

### 5.3 实测：这三对像素就是"Flip 与 Tile 不同"的现场（批次 1）

`v2tiling`（瓦片 80×48 @ (16,16)，索引 x[0,2] y[0,2]）：

| 用例 | `mag-left@tile(1,0)` = (107,39) | `mag-right@tile(1,0)` = (165,39) | `cyan-top@tile(0,1)` = (55,71) | `cyan-bot@tile(0,1)` = (55,105) |
|---|---|---|---|---|
| `*_tile_v2tiling` | **`#FFFF00FF`** 品红 | `#FF202830` | **`#FF00FFFF`** 青 | `#FF202830` |
| `*_flipx_v2tiling` | `#FF202830` | **`#FFFF00FF`** | `#FF00FFFF` | `#FF202830` |
| `*_flipy_v2tiling` | `#FFFF00FF` | `#FF202830` | `#FF202830` | **`#FF00FFFF`** |
| `*_flipxy_v2tiling` | `#FF202830` | **`#FFFF00FF`** | `#FF202830` | **`#FF00FFFF`** |
| `*_none_v2tiling` | `#FF808080` 背景 | `#FF808080` | `#FF808080` | `#FF808080` |

`ImageBrush` 与 `DrawingBrush` 在这四个点上**逐字节相同**（交叉对照通过）。
`v3offset` 同理（判别点坐标随之平移：`mag-left@tile(1,0)` = (167,63) 等）。

---

## 6. 批次 1 结论（`TileMode` 五档 × 两源 × 三档 Viewport）

这些结论同时被①真机像素、②一个**独立实现的瓦片模型**（`Program.Predicted()`，
把设备像素反算到源坐标）双重确认——模型在**全部 30 个 core 用例**上与真机像素
**逐点完全一致**（如 `243/243`、`238/238`、`212/212`），即下面这套语义可以照抄：

1. **基准格（tile index 0）永不翻转。** 翻转只发生在奇数索引格上。
2. **瓦片索引从 `Viewport` 原点起算**，`index = floor((像素 - 原点) / 瓦片尺寸)`；
   **负索引同样按奇偶翻转**（`v3offset` 里目标左上角那些格子索引是 −1 ⇒ 是翻转格，
   实测 `core_image_flipx_v3offset` 模型吻合 212/212，证明 WPF 确实这么干）。
3. **`FlipX` = 瓦片内水平镜像**（`x → tileW − x`），`FlipY` 竖直，`FlipXY` 两者都做。
   奇数索引的**行/列**分别决定：`i` 奇 ⇒ 水平镜像，`j` 奇 ⇒ 垂直镜像。
4. **`TileMode.None` 只画基准格**，基准格之外完全是背景（上面表格里 `none` 那行四个点
   全是 `#FF808080`）——即"不铺开"，而不是"钳位延伸"。
5. **`v1same`（Viewport 与目标同尺寸）五档在内部完全相同**（0 个差异采样点）：
   只有一格时翻转无从观察。这条对 Linux 侧是个有用的等价类。
6. **绝对单位的 `Viewport` 用的是"被填充图形的局部坐标系"（原点 = 包围盒左上角），
   不是画布/设备坐标。** 证据：`units_vpabs_*` 用例对两种读法做 A/B 假设检验——
   局部原点解释 **194/194** 完全吻合，画布原点解释只有 **20/216**（加上瓦片边界与判别点后
   为 229/229 vs 20/221）；判别像素见下：
   目标 `(16,16,200,120)`、`Viewport=(10,10,80,48)` 时，`(120,45)` 处真机是品红
   （源坐标 ≈ (5.8,13.0)，即瓦片原点在 (26,26)）；若按画布原点解释应落在源 x≈12.2
   （底色/三角），与实测不符。

### 6.1 额外发现：ImageBrush 的瓦片边界取样（Linux 侧务必注意）

**单格档里 `Tile`/`FlipX`/`FlipY` 在最外圈 1–3px 上也会不同**——因为 `ImageBrush` 的
双线性取样在图像边界会取到**相邻瓦片**的内容，而那个邻居正是被镜像过的。
`DrawingBrush`/`VisualBrush`（矢量）没有这个现象（实测差异 0）。

`v1same` 四角（内缩 1px）实测（`core_image_*`）：

| 角点 | `None` | `Tile` | `FlipX` | `FlipY` | `FlipXY` |
|---|---|---|---|---|---|
| tl (17,17) | `#FFD02020` | `#FF9A4635` | `#FFBE2532` | `#FFA24228` | `#FFD02020` |
| tr (214,17) | `#FF20A040` | `#FF57833A` | `#FF34A33D` | `#FF4D7F38` | `#FF20A040` |
| bl (17,134) | `#FF2050D0` | `#FF5A6996` | `#FF314BBF` | `#FF526DA2` | `#FF2050D0` |
| br (214,134) | `#FFE0C020` | `#FFA5A04B` | `#FFCDBD23` | `#FFAFA34D` | `#FFE0C020` |

注意 `FlipXY` 在这一组里恰好等于 `None`（双镜像后的邻居角点又变回原色）——
这不是巧合而是可解释的，也说明**不能靠"角点不相等"来判断实现是否对**。

---

## 7. 结果文件怎么读（`windows-results.json`）

```
format / generatedAtUtc / sabotage
environment            —— §1 的全部版本留痕（含 PresentationCore 与 wpfgfx_cor3 的 SHA256）
caseCount = 74
selfTest               —— 比较器自检（必须 ok）
failures[]             —— 空数组才算这批数据可用
cases[]                —— 每个用例：
    id / family / source / tileModeDeclared / tileModeRendered / sabotaged
    viewport / viewportUnits / viewbox / viewboxUnits / stretch / alignmentX/Y / targetRect
    png / pngBytes / pngSha256          —— PNG 与其哈希（可校验传输完整性）
    pngSize{dpiX,dpiY,pixelFormat}      —— 96 DPI / Bgra32 直通 alpha
    layout{actualWidth,actualHeight,renderedBounds,dpiScale,textFormattingMode,bitmapScalingMode}
    viewportOriginInterpretation + viewportOriginHypotheses
                                        —— 绝对单位 Viewport 的两种读法各自的吻合点数
    tileGeometry{originX,originY,tileWidth,tileHeight,indexLeft/Right/Top/Bottom}
    modelApplicable / stats{distinctSampledColors,paintedSamples,modelChecked,modelMatched,...}
    checks{ok,failures[]}
    samples[]           —— 每个采样点：x,y,role(grid|corner|tile-boundary-x|tile-boundary-y|discriminator),
                           note, hex(#AARRGGBB), modelHex, modelUsable
discrimination[]       —— 93 条"同组内两档 TileMode 必须不同"的对比结果
```

采样点覆盖（每个用例 388–454 点）：**24×16 网格**（覆盖整个目标矩形）+ **4 个角**（内缩 1px）+
**每条瓦片边界 ±2/±1/0 px** + **瓦片 (0,0)/(1,0)/(0,1)/(1,1) 的四个具名判别点**。
颜色一律 `#AARRGGBB`（`A` 一并给出，含 alpha 家族）。

---

## 8. 本次做了哪些独立校验（不只看程序自称）

1. **传输完整性**：Linux 侧逐文件重算 SHA256 与 `pngBytes`，74/74 与
   `windows-results.json` 记录一致。
2. **像素抽样复核**：用 PIL 重新解码每个 PNG，对每个用例抽查 40 个采样点，
   与 JSON 里的 `hex` 逐点比对，**0 失配**（说明 JSON 里的颜色确实来自这些 PNG）。
3. **模型吻合率**：30 个 core 用例 100%（`modelMatched == modelChecked`），
   15 个 visual 用例也是 100%（文字区域被模型标为"未知"，不参与计分）。
4. **破坏性自检**：见 §4 第 6 条（退出码 2、51 条断言变红）。

---

## 9. 未覆盖 / 后续

- 本批次**未覆盖**：`BitmapCacheBrush`、`DrawingBrush` 的 `Viewport` 带 `Stretch=None`
  与 `TileMode=Flip*` 的组合、`ViewboxUnits=Relative` 与 `Stretch=None` 的交互、
  位图 `BitmapScalingMode` 显式设为 `NearestNeighbor`/`HighQuality` 的三档对照、
  非 96 DPI、`TextFormattingMode=Display`、`VisualBrush` 的 `Viewbox` 自动取界行为。
- `alpha` 家族只做了 4 例（覆盖直通/预乘与不透明/透明背景两个维度），
  没有对每个 `TileMode` 都铺一遍。
- `units_viewbox_subregion_2x_*` 两个用例的模型不适用（`Viewbox` 取了子区域，
  源坐标要再乘一次缩放），因此它们的 `modelApplicable=false`、不参与模型计分；
  像素本身仍然可用（`Viewbox=(0,0,16,16)` 确实放大了左上半区）。

---

## 10. 文件清单

| 路径 | 说明 |
|---|---|
| `cases.json` | 74 个用例的完整规格（源图案定义、判别点定义、每个用例的全部笔刷参数） |
| `windows-results.json` | 全部结果：环境、逐用例元数据 + 采样点、93 条判别力对比、自检 |
| `out/*.png` | 74 张真机渲染 PNG（Bgra32 直通 alpha，256×256 @96DPI） |
| `out/run-normal.log` | 正常采集的控制台输出（`cases=74 failures=0`） |
| `out/run-sabotage.log` | 破坏性自检输出（39 条 `NO DISCRIMINATION`、`failures=51`） |
| `src/` | Windows 侧采集程序源码与 csproj（Linux 侧零构建，只在 Windows 上 `dotnet build`） |
| `PROVENANCE.md` | 本文件 |

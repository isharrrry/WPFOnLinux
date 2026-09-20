# U1c 几何 oracle 对拍摘要（自动生成）

- 用例总数：215
- 逐位相同：134
- 浮点容差内相同：34
- 几何等价但发射顺序不同：16
- 我方偏差：10
- 结构性不一致（HRESULT / 键集合 / 异常）：21

## 逐函数

| 函数 | 用例 | 逐位 | 容差内 | 顺序 | 偏差 | 结构 |
|---|---|---|---|---|---|---|
| `ExportProbe` | 1 | 1 | 0 | 0 | 0 | 0 |
| `MilUtility_ArcToBezier` | 29 | 5 | 21 | 0 | 3 | 0 |
| `MilUtility_CopyPixelBuffer` | 21 | 21 | 0 | 0 | 0 | 0 |
| `MilUtility_GeometryGetArea` | 19 | 14 | 5 | 0 | 0 | 0 |
| `MilUtility_GetPointAtLengthFraction` | 10 | 8 | 0 | 0 | 1 | 1 |
| `MilUtility_GetTileBrushMapping` | 23 | 18 | 0 | 0 | 5 | 0 |
| `MilUtility_PathGeometryBounds` | 11 | 11 | 0 | 0 | 0 | 0 |
| `MilUtility_PathGeometryCombine` | 22 | 11 | 0 | 10 | 0 | 1 |
| `MilUtility_PathGeometryFlatten` | 14 | 3 | 8 | 0 | 0 | 3 |
| `MilUtility_PathGeometryHitTest` | 25 | 25 | 0 | 0 | 0 | 0 |
| `MilUtility_PathGeometryHitTestPathGeometry` | 7 | 7 | 0 | 0 | 0 | 0 |
| `MilUtility_PathGeometryOutline` | 10 | 2 | 0 | 5 | 0 | 3 |
| `MilUtility_PathGeometryWiden` | 16 | 1 | 0 | 1 | 1 | 13 |
| `MilUtility_PolygonBounds` | 4 | 4 | 0 | 0 | 0 | 0 |
| `MilUtility_PolygonHitTest` | 3 | 3 | 0 | 0 | 0 | 0 |

## 非一致明细

### `arc_radii_zero` — Deviation

- 意图：半径全 0 → cPieces=0（直线）
- 结论：首个数值差异：points[0]: win=-5.480753890145935E-36 lin=40 (Δabs=40 Δrel=1)（共 2 处）
- Windows：`hr=0x00000000 cPieces=0 pointCount=1 points=[-5.480753890145935E-36,4.5909340288209657E-41]`
- Linux　：`hr=0x00000000 cPieces=0 pointCount=1 points=[40,20]`
- 差异明细：
  - `points[0]: win=-5.480753890145935E-36 lin=40 (Δabs=40 Δrel=1)`
  - `points[1]: win=4.5909340288209657E-41 lin=20 (Δabs=20 Δrel=1)`

### `arc_radius_x_zero` — Deviation

- 意图：x 半径为 0
- 结论：首个数值差异：points[0]: win=-5.480753890145935E-36 lin=40 (Δabs=40 Δrel=1)（共 2 处）
- Windows：`hr=0x00000000 cPieces=0 pointCount=1 points=[-5.480753890145935E-36,4.5909340288209657E-41]`
- Linux　：`hr=0x00000000 cPieces=0 pointCount=1 points=[40,20]`
- 差异明细：
  - `points[0]: win=-5.480753890145935E-36 lin=40 (Δabs=40 Δrel=1)`
  - `points[1]: win=4.5909340288209657E-41 lin=20 (Δabs=20 Δrel=1)`

### `arc_radius_y_zero` — Deviation

- 意图：y 半径为 0
- 结论：首个数值差异：points[0]: win=-5.480753890145935E-36 lin=40 (Δabs=40 Δrel=1)（共 2 处）
- Windows：`hr=0x00000000 cPieces=0 pointCount=1 points=[-5.480753890145935E-36,4.5909340288209657E-41]`
- Linux　：`hr=0x00000000 cPieces=0 pointCount=1 points=[40,20]`
- 差异明细：
  - `points[0]: win=-5.480753890145935E-36 lin=40 (Δabs=40 Δrel=1)`
  - `points[1]: win=4.5909340288209657E-41 lin=20 (Δabs=20 Δrel=1)`

### `flatten_circle_tol_0_001` — Structural

- 意图：容差极小 → 点数应当多
- 结论：fig0.pts 长度不同：win=1266 lin=1502
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=633 fig0.typeCount=632 figCount=1 outFillRule=0 fig0.pts=[90,50,89.99918365478516,50.258689880371094,89.9967269897461,50.51699447631836,89.99264526367188,50.774906158447266,89.9869384765625,51.03241729736328,89.97960662841797,51.289527893066406,89.97066497802734,51.54623031616211,89.96011352539062,51.802520751953125,89.94795227050781,52.05839538574219,89.93419647216797,52.313846588134766,89.91883850097656,52.568870544433594,89.90189361572266,52.82345962524414,…] fig0.start=[90,50] fig0.types=[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,…]`
- Linux　：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=751 fig0.typeCount=750 figCount=1 outFillRule=0 fig0.pts=[90,50,89.99917602539062,50.25869369506836,89.99673461914062,50.516998291015625,89.99264526367188,50.774906158447266,89.9869384765625,51.03241729736328,89.97960662841797,51.289527893066406,89.97066497802734,51.546234130859375,89.96011352539062,51.80252456665039,89.94795227050781,52.05839538574219,89.93419647216797,52.313846588134766,89.9188461303711,52.568870544433594,89.90190887451172,52.823463439941406,…] fig0.start=[90,50] fig0.types=[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,…]`
- 差异明细：
  - `fig0.pointCount: win=633 lin=751 (Δabs=118 Δrel=0.157)`
  - `fig0.typeCount: win=632 lin=750 (Δabs=118 Δrel=0.157)`

### `flatten_circle_tol_0_25` — Structural

- 结论：fig0.pts 长度不同：win=98 lin=114
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=49 fig0.typeCount=48 figCount=1 outFillRule=0 fig0.pts=[90,50,89.79348754882812,54.08976745605469,89.18733978271484,58.061397552490234,88.2016830444336,61.894779205322266,86.85660552978516,65.56980895996094,83.16863250732422,72.3643798828125,78.28427124023438,78.28427124023438,72.3643798828125,83.16863250732422,65.56980895996094,86.85660552978516,61.894779205322266,88.2016830444336,58.061397552490234,89.18733978271484,54.08976745605469,89.79348754882812,…] fig0.start=[90,50] fig0.types=[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,…]`
- Linux　：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=57 fig0.typeCount=56 figCount=1 outFillRule=0 fig0.pts=[90,50,89.79348754882812,54.08977127075195,89.18734741210938,58.0614013671875,88.20167541503906,61.89478302001953,86.85660552978516,65.56980895996094,85.1722183227539,69.06637573242188,83.16863250732422,72.3643798828125,78.28427124023438,78.28427124023438,72.3643798828125,83.16863250732422,69.06637573242188,85.1722183227539,65.56980895996094,86.85660552978516,61.89478302001953,88.20167541503906,…] fig0.start=[90,50] fig0.types=[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,…]`
- 差异明细：
  - `fig0.pointCount: win=49 lin=57 (Δabs=8 Δrel=0.14)`
  - `fig0.typeCount: win=48 lin=56 (Δabs=8 Δrel=0.143)`

### `flatten_circle_tol_0` — Structural

- 意图：容差 0：上游 GetAbsoluteTolerance 会怎么处理？
- 结论：fig0.pts 长度不同：win=8194 lin=130
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=4097 fig0.typeCount=4096 figCount=1 outFillRule=0 fig0.pts=[90,50,89.99994659423828,50.0647087097168,89.99979400634766,50.12939453125,89.99954223632812,50.194053649902344,89.99918365478516,50.258689880371094,89.99871826171875,50.32330322265625,89.99816131591797,50.38788986206055,89.99749755859375,50.45245361328125,89.9967269897461,50.51699447631836,89.99585723876953,50.58150863647461,89.99488830566406,50.645999908447266,89.99382019042969,50.71046447753906,…] fig0.start=[90,50] fig0.types=[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,…]`
- Linux　：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=65 fig0.typeCount=64 figCount=1 outFillRule=0 fig0.pts=[90,50,89.79348754882812,54.08977127075195,89.18734741210938,58.0614013671875,88.20167541503906,61.89478302001953,86.85660552978516,65.56980895996094,85.1722183227539,69.06637573242188,83.16863250732422,72.3643798828125,80.8659439086914,75.44371032714844,78.28427124023438,78.28427124023438,75.44371032714844,80.8659439086914,72.3643798828125,83.16863250732422,69.06637573242188,85.1722183227539,…] fig0.start=[90,50] fig0.types=[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,…]`
- 差异明细：
  - `fig0.pointCount: win=4097 lin=65 (Δabs=4.03E+03 Δrel=0.984)`
  - `fig0.typeCount: win=4096 lin=64 (Δabs=4.03E+03 Δrel=0.984)`

### `combine_overlap_xor` — Reordered

- 意图：两个相交矩形的四种布尔模式
- 结论：几何等价，但至少一个图形的点序不同（环内旋转或反向）
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=7 fig0.typeCount=6 fig1.closed=1 fig1.filled=1 fig1.pointCount=7 fig1.typeCount=6 figCount=2 outFillRule=1 fig0.pts=[10,5,15,5,15,15,5,15,5,10,10,10,10,5] fig0.start=[10,5] fig0.types=[1,1,1,1,1,1] fig1.pts=[0,0,10,0,10,5,5,5,5,10,0,10,0,0] fig1.start=[0,0] fig1.types=[1,1,1,1,1,1]`
- Linux　：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=7 fig0.typeCount=6 fig1.closed=1 fig1.filled=1 fig1.pointCount=7 fig1.typeCount=6 figCount=2 outFillRule=1 fig0.pts=[0,0,10,0,10,5,5,5,5,10,0,10,0,0] fig0.start=[0,0] fig0.types=[1,1,1,1,1,1] fig1.pts=[5,15,5,10,10,10,10,5,15,5,15,15,5,15] fig1.start=[5,15] fig1.types=[1,1,1,1,1,1]`
- 差异明细：
  - `fig0.start[0]: win=10 lin=0 (Δabs=10 Δrel=1)`
  - `fig0.start[1]: win=5 lin=0 (Δabs=5 Δrel=1)`
  - `fig0.pts[0]: win=10 lin=0 (Δabs=10 Δrel=1)`
  - `fig0.pts[1]: win=5 lin=0 (Δabs=5 Δrel=1)`
  - `fig0.pts[2]: win=15 lin=10 (Δabs=5 Δrel=0.333)`
  - `fig0.pts[3]: win=5 lin=0 (Δabs=5 Δrel=1)`
  - `fig0.pts[4]: win=15 lin=10 (Δabs=5 Δrel=0.333)`
  - `fig0.pts[5]: win=15 lin=5 (Δabs=10 Δrel=0.667)`
  - `fig0.pts[7]: win=15 lin=5 (Δabs=10 Δrel=0.667)`
  - `fig0.pts[10]: win=10 lin=0 (Δabs=10 Δrel=1)`
  - `fig0.pts[12]: win=10 lin=0 (Δabs=10 Δrel=1)`
  - `fig0.pts[13]: win=5 lin=0 (Δabs=5 Δrel=1)`

### `combine_disjoint_union` — Reordered

- 意图：相离：Xor/Exclude 与 Union 应当同形
- 结论：几何等价，但至少一个图形的点序不同（环内旋转或反向）
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 fig1.closed=1 fig1.filled=1 fig1.pointCount=5 fig1.typeCount=4 figCount=2 outFillRule=1 fig0.pts=[20,20,30,20,30,30,20,30,20,20] fig0.start=[20,20] fig0.types=[1,1,1,1] fig1.pts=[0,0,10,0,10,10,0,10,0,0] fig1.start=[0,0] fig1.types=[1,1,1,1]`
- Linux　：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 fig1.closed=1 fig1.filled=1 fig1.pointCount=5 fig1.typeCount=4 figCount=2 outFillRule=1 fig0.pts=[0,0,10,0,10,10,0,10,0,0] fig0.start=[0,0] fig0.types=[1,1,1,1] fig1.pts=[20,20,30,20,30,30,20,30,20,20] fig1.start=[20,20] fig1.types=[1,1,1,1]`
- 差异明细：
  - `fig0.start[0]: win=20 lin=0 (Δabs=20 Δrel=1)`
  - `fig0.start[1]: win=20 lin=0 (Δabs=20 Δrel=1)`
  - `fig0.pts[0]: win=20 lin=0 (Δabs=20 Δrel=1)`
  - `fig0.pts[1]: win=20 lin=0 (Δabs=20 Δrel=1)`
  - `fig0.pts[2]: win=30 lin=10 (Δabs=20 Δrel=0.667)`
  - `fig0.pts[3]: win=20 lin=0 (Δabs=20 Δrel=1)`
  - `fig0.pts[4]: win=30 lin=10 (Δabs=20 Δrel=0.667)`
  - `fig0.pts[5]: win=30 lin=10 (Δabs=20 Δrel=0.667)`
  - `fig0.pts[6]: win=20 lin=0 (Δabs=20 Δrel=1)`
  - `fig0.pts[7]: win=30 lin=10 (Δabs=20 Δrel=0.667)`
  - `fig0.pts[8]: win=20 lin=0 (Δabs=20 Δrel=1)`
  - `fig0.pts[9]: win=20 lin=0 (Δabs=20 Δrel=1)`

### `combine_disjoint_xor` — Reordered

- 意图：相离：Xor/Exclude 与 Union 应当同形
- 结论：几何等价，但至少一个图形的点序不同（环内旋转或反向）
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 fig1.closed=1 fig1.filled=1 fig1.pointCount=5 fig1.typeCount=4 figCount=2 outFillRule=1 fig0.pts=[20,20,30,20,30,30,20,30,20,20] fig0.start=[20,20] fig0.types=[1,1,1,1] fig1.pts=[0,0,10,0,10,10,0,10,0,0] fig1.start=[0,0] fig1.types=[1,1,1,1]`
- Linux　：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 fig1.closed=1 fig1.filled=1 fig1.pointCount=5 fig1.typeCount=4 figCount=2 outFillRule=1 fig0.pts=[0,0,10,0,10,10,0,10,0,0] fig0.start=[0,0] fig0.types=[1,1,1,1] fig1.pts=[20,20,30,20,30,30,20,30,20,20] fig1.start=[20,20] fig1.types=[1,1,1,1]`
- 差异明细：
  - `fig0.start[0]: win=20 lin=0 (Δabs=20 Δrel=1)`
  - `fig0.start[1]: win=20 lin=0 (Δabs=20 Δrel=1)`
  - `fig0.pts[0]: win=20 lin=0 (Δabs=20 Δrel=1)`
  - `fig0.pts[1]: win=20 lin=0 (Δabs=20 Δrel=1)`
  - `fig0.pts[2]: win=30 lin=10 (Δabs=20 Δrel=0.667)`
  - `fig0.pts[3]: win=20 lin=0 (Δabs=20 Δrel=1)`
  - `fig0.pts[4]: win=30 lin=10 (Δabs=20 Δrel=0.667)`
  - `fig0.pts[5]: win=30 lin=10 (Δabs=20 Δrel=0.667)`
  - `fig0.pts[6]: win=20 lin=0 (Δabs=20 Δrel=1)`
  - `fig0.pts[7]: win=30 lin=10 (Δabs=20 Δrel=0.667)`
  - `fig0.pts[8]: win=20 lin=0 (Δabs=20 Δrel=1)`
  - `fig0.pts[9]: win=20 lin=0 (Δabs=20 Δrel=1)`

### `combine_disjoint_exclude` — Reordered

- 意图：相离：Xor/Exclude 与 Union 应当同形
- 结论：几何等价，但至少一个图形的点序不同（环内旋转或反向）
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 figCount=1 outFillRule=1 fig0.pts=[0,0,10,0,10,10,0,10,0,0] fig0.start=[0,0] fig0.types=[1,1,1,1]`
- Linux　：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 figCount=1 outFillRule=1 fig0.pts=[10,0,0,0,0,10,10,10,10,0] fig0.start=[10,0] fig0.types=[1,1,1,1]`
- 差异明细：
  - `fig0.start[0]: win=0 lin=10 (Δabs=10 Δrel=1)`
  - `fig0.pts[0]: win=0 lin=10 (Δabs=10 Δrel=1)`
  - `fig0.pts[2]: win=10 lin=0 (Δabs=10 Δrel=1)`
  - `fig0.pts[4]: win=10 lin=0 (Δabs=10 Δrel=1)`
  - `fig0.pts[6]: win=0 lin=10 (Δabs=10 Δrel=1)`
  - `fig0.pts[8]: win=0 lin=10 (Δabs=10 Δrel=1)`

### `combine_nested_union` — Reordered

- 意图：内含：Exclude 应当出洞
- 结论：几何等价，但至少一个图形的点序不同（环内旋转或反向）
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 figCount=1 outFillRule=1 fig0.pts=[0,0,10,0,10,10,0,10,0,0] fig0.start=[0,0] fig0.types=[1,1,1,1]`
- Linux　：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 figCount=1 outFillRule=1 fig0.pts=[10,0,0,0,0,10,10,10,10,0] fig0.start=[10,0] fig0.types=[1,1,1,1]`
- 差异明细：
  - `fig0.start[0]: win=0 lin=10 (Δabs=10 Δrel=1)`
  - `fig0.pts[0]: win=0 lin=10 (Δabs=10 Δrel=1)`
  - `fig0.pts[2]: win=10 lin=0 (Δabs=10 Δrel=1)`
  - `fig0.pts[4]: win=10 lin=0 (Δabs=10 Δrel=1)`
  - `fig0.pts[6]: win=0 lin=10 (Δabs=10 Δrel=1)`
  - `fig0.pts[8]: win=0 lin=10 (Δabs=10 Δrel=1)`

### `combine_nested_xor` — Reordered

- 意图：内含：Exclude 应当出洞
- 结论：几何等价，但至少一个图形的点序不同（环内旋转或反向）
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 fig1.closed=1 fig1.filled=1 fig1.pointCount=5 fig1.typeCount=4 figCount=2 outFillRule=1 fig0.pts=[2,2,2,8,8,8,8,2,2,2] fig0.start=[2,2] fig0.types=[1,1,1,1] fig1.pts=[0,0,10,0,10,10,0,10,0,0] fig1.start=[0,0] fig1.types=[1,1,1,1]`
- Linux　：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 fig1.closed=1 fig1.filled=1 fig1.pointCount=5 fig1.typeCount=4 figCount=2 outFillRule=1 fig0.pts=[0,0,10,0,10,10,0,10,0,0] fig0.start=[0,0] fig0.types=[1,1,1,1] fig1.pts=[2,2,8,2,8,8,2,8,2,2] fig1.start=[2,2] fig1.types=[1,1,1,1]`
- 差异明细：
  - `fig0.start[0]: win=2 lin=0 (Δabs=2 Δrel=1)`
  - `fig0.start[1]: win=2 lin=0 (Δabs=2 Δrel=1)`
  - `fig0.pts[0]: win=2 lin=0 (Δabs=2 Δrel=1)`
  - `fig0.pts[1]: win=2 lin=0 (Δabs=2 Δrel=1)`
  - `fig0.pts[2]: win=2 lin=10 (Δabs=8 Δrel=0.8)`
  - `fig0.pts[3]: win=8 lin=0 (Δabs=8 Δrel=1)`
  - `fig0.pts[4]: win=8 lin=10 (Δabs=2 Δrel=0.2)`
  - `fig0.pts[5]: win=8 lin=10 (Δabs=2 Δrel=0.2)`
  - `fig0.pts[6]: win=8 lin=0 (Δabs=8 Δrel=1)`
  - `fig0.pts[7]: win=2 lin=10 (Δabs=8 Δrel=0.8)`
  - `fig0.pts[8]: win=2 lin=0 (Δabs=2 Δrel=1)`
  - `fig0.pts[9]: win=2 lin=0 (Δabs=2 Δrel=1)`

### `combine_nested_exclude` — Reordered

- 意图：内含：Exclude 应当出洞
- 结论：几何等价，但至少一个图形的点序不同（环内旋转或反向）
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 fig1.closed=1 fig1.filled=1 fig1.pointCount=5 fig1.typeCount=4 figCount=2 outFillRule=1 fig0.pts=[2,2,2,8,8,8,8,2,2,2] fig0.start=[2,2] fig0.types=[1,1,1,1] fig1.pts=[0,0,10,0,10,10,0,10,0,0] fig1.start=[0,0] fig1.types=[1,1,1,1]`
- Linux　：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 fig1.closed=1 fig1.filled=1 fig1.pointCount=5 fig1.typeCount=4 figCount=2 outFillRule=1 fig0.pts=[0,0,10,0,10,10,0,10,0,0] fig0.start=[0,0] fig0.types=[1,1,1,1] fig1.pts=[2,2,8,2,8,8,2,8,2,2] fig1.start=[2,2] fig1.types=[1,1,1,1]`
- 差异明细：
  - `fig0.start[0]: win=2 lin=0 (Δabs=2 Δrel=1)`
  - `fig0.start[1]: win=2 lin=0 (Δabs=2 Δrel=1)`
  - `fig0.pts[0]: win=2 lin=0 (Δabs=2 Δrel=1)`
  - `fig0.pts[1]: win=2 lin=0 (Δabs=2 Δrel=1)`
  - `fig0.pts[2]: win=2 lin=10 (Δabs=8 Δrel=0.8)`
  - `fig0.pts[3]: win=8 lin=0 (Δabs=8 Δrel=1)`
  - `fig0.pts[4]: win=8 lin=10 (Δabs=2 Δrel=0.2)`
  - `fig0.pts[5]: win=8 lin=10 (Δabs=2 Δrel=0.2)`
  - `fig0.pts[6]: win=8 lin=0 (Δabs=8 Δrel=1)`
  - `fig0.pts[7]: win=2 lin=10 (Δabs=8 Δrel=0.8)`
  - `fig0.pts[8]: win=2 lin=0 (Δabs=2 Δrel=1)`
  - `fig0.pts[9]: win=2 lin=0 (Δabs=2 Δrel=1)`

### `combine_identical_union` — Reordered

- 意图：完全相同
- 结论：几何等价，但至少一个图形的点序不同（环内旋转或反向）
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 figCount=1 outFillRule=1 fig0.pts=[0,0,10,0,10,10,0,10,0,0] fig0.start=[0,0] fig0.types=[1,1,1,1]`
- Linux　：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 figCount=1 outFillRule=1 fig0.pts=[10,0,0,0,0,10,10,10,10,0] fig0.start=[10,0] fig0.types=[1,1,1,1]`
- 差异明细：
  - `fig0.start[0]: win=0 lin=10 (Δabs=10 Δrel=1)`
  - `fig0.pts[0]: win=0 lin=10 (Δabs=10 Δrel=1)`
  - `fig0.pts[2]: win=10 lin=0 (Δabs=10 Δrel=1)`
  - `fig0.pts[4]: win=10 lin=0 (Δabs=10 Δrel=1)`
  - `fig0.pts[6]: win=0 lin=10 (Δabs=10 Δrel=1)`
  - `fig0.pts[8]: win=0 lin=10 (Δabs=10 Δrel=1)`

### `combine_touching_union` — Structural

- 意图：共边相切：Union 应当合成一个矩形还是两个图形？
- 结论：fig0.pts 长度不同：win=14 lin=12
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=7 fig0.typeCount=6 figCount=1 outFillRule=1 fig0.pts=[0,0,10,0,20,0,20,10,10,10,0,10,0,0] fig0.start=[0,0] fig0.types=[1,1,1,1,1,1]`
- Linux　：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=6 fig0.typeCount=5 figCount=1 outFillRule=1 fig0.pts=[10,0,0,0,0,10,20,10,20,0,10,0] fig0.start=[10,0] fig0.types=[1,1,1,1,1]`
- 差异明细：
  - `fig0.pointCount: win=7 lin=6 (Δabs=1 Δrel=0.143)`
  - `fig0.typeCount: win=6 lin=5 (Δabs=1 Δrel=0.167)`
  - `fig0.start[0]: win=0 lin=10 (Δabs=10 Δrel=1)`

### `combine_fillrule_nonzero` — Reordered

- 意图：两个输入都是 Nonzero
- 结论：几何等价，但至少一个图形的点序不同（环内旋转或反向）
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 fig1.closed=1 fig1.filled=1 fig1.pointCount=5 fig1.typeCount=4 figCount=2 outFillRule=1 fig0.pts=[2,2,2,8,8,8,8,2,2,2] fig0.start=[2,2] fig0.types=[1,1,1,1] fig1.pts=[0,0,10,0,10,10,0,10,0,0] fig1.start=[0,0] fig1.types=[1,1,1,1]`
- Linux　：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 fig1.closed=1 fig1.filled=1 fig1.pointCount=5 fig1.typeCount=4 figCount=2 outFillRule=1 fig0.pts=[0,0,10,0,10,10,0,10,0,0] fig0.start=[0,0] fig0.types=[1,1,1,1] fig1.pts=[2,2,8,2,8,8,2,8,2,2] fig1.start=[2,2] fig1.types=[1,1,1,1]`
- 差异明细：
  - `fig0.start[0]: win=2 lin=0 (Δabs=2 Δrel=1)`
  - `fig0.start[1]: win=2 lin=0 (Δabs=2 Δrel=1)`
  - `fig0.pts[0]: win=2 lin=0 (Δabs=2 Δrel=1)`
  - `fig0.pts[1]: win=2 lin=0 (Δabs=2 Δrel=1)`
  - `fig0.pts[2]: win=2 lin=10 (Δabs=8 Δrel=0.8)`
  - `fig0.pts[3]: win=8 lin=0 (Δabs=8 Δrel=1)`
  - `fig0.pts[4]: win=8 lin=10 (Δabs=2 Δrel=0.2)`
  - `fig0.pts[5]: win=8 lin=10 (Δabs=2 Δrel=0.2)`
  - `fig0.pts[6]: win=8 lin=0 (Δabs=8 Δrel=1)`
  - `fig0.pts[7]: win=2 lin=10 (Δabs=8 Δrel=0.8)`
  - `fig0.pts[8]: win=2 lin=0 (Δabs=2 Δrel=1)`
  - `fig0.pts[9]: win=2 lin=0 (Δabs=2 Δrel=1)`

### `combine_matrix1_only` — Reordered

- 意图：只给 geometry1 矩阵
- 结论：几何等价，但至少一个图形的点序不同（环内旋转或反向）
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 figCount=1 outFillRule=1 fig0.pts=[0,0,20,0,20,20,0,20,0,0] fig0.start=[0,0] fig0.types=[1,1,1,1]`
- Linux　：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 figCount=1 outFillRule=1 fig0.pts=[20,0,0,0,0,20,20,20,20,0] fig0.start=[20,0] fig0.types=[1,1,1,1]`
- 差异明细：
  - `fig0.start[0]: win=0 lin=20 (Δabs=20 Δrel=1)`
  - `fig0.pts[0]: win=0 lin=20 (Δabs=20 Δrel=1)`
  - `fig0.pts[2]: win=20 lin=0 (Δabs=20 Δrel=1)`
  - `fig0.pts[4]: win=20 lin=0 (Δabs=20 Δrel=1)`
  - `fig0.pts[6]: win=0 lin=20 (Δabs=20 Δrel=1)`
  - `fig0.pts[8]: win=0 lin=20 (Δabs=20 Δrel=1)`

### `outline_circle_tol_0_001` — Reordered

- 意图：rTolerance 是否影响 Outline 的输出点数？
- 结论：几何等价，但至少一个图形的点序不同（环内旋转或反向）
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=13 fig0.typeCount=4 figCount=1 outFillRule=0 fig0.pts=[50,10,72.09139251708984,10,90,27.90860939025879,90,50,90,72.09139251708984,72.09139251708984,90,50,90,27.90860939025879,90,10,72.09139251708984,10,50,10,27.90860939025879,27.90860939025879,10,…] fig0.start=[50,10] fig0.types=[2,2,2,2]`
- Linux　：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=13 fig0.typeCount=4 figCount=1 outFillRule=0 fig0.pts=[90,50,90,72.09139251708984,72.09139251708984,90,50,90,27.90860939025879,90,10,72.09139251708984,10,50,10,27.90860939025879,27.90860939025879,10,50,10,72.09139251708984,10,90,27.90860939025879,…] fig0.start=[90,50] fig0.types=[2,2,2,2]`
- 差异明细：
  - `fig0.start[0]: win=50 lin=90 (Δabs=40 Δrel=0.444)`
  - `fig0.start[1]: win=10 lin=50 (Δabs=40 Δrel=0.8)`
  - `fig0.pts[0]: win=50 lin=90 (Δabs=40 Δrel=0.444)`
  - `fig0.pts[1]: win=10 lin=50 (Δabs=40 Δrel=0.8)`
  - `fig0.pts[2]: win=72.09139251708984 lin=90 (Δabs=17.9 Δrel=0.199)`
  - `fig0.pts[3]: win=10 lin=72.09139251708984 (Δabs=62.1 Δrel=0.861)`
  - `fig0.pts[4]: win=90 lin=72.09139251708984 (Δabs=17.9 Δrel=0.199)`
  - `fig0.pts[5]: win=27.90860939025879 lin=90 (Δabs=62.1 Δrel=0.69)`
  - `fig0.pts[6]: win=90 lin=50 (Δabs=40 Δrel=0.444)`
  - `fig0.pts[7]: win=50 lin=90 (Δabs=40 Δrel=0.444)`
  - `fig0.pts[8]: win=90 lin=27.90860939025879 (Δabs=62.1 Δrel=0.69)`
  - `fig0.pts[9]: win=72.09139251708984 lin=90 (Δabs=17.9 Δrel=0.199)`

### `outline_circle_tol_0_1` — Reordered

- 结论：几何等价，但至少一个图形的点序不同（环内旋转或反向）
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=13 fig0.typeCount=4 figCount=1 outFillRule=0 fig0.pts=[50,10,72.09139251708984,10,90,27.90860939025879,90,50,90,72.09139251708984,72.09139251708984,90,50,90,27.90860939025879,90,10,72.09139251708984,10,50,10,27.90860939025879,27.90860939025879,10,…] fig0.start=[50,10] fig0.types=[2,2,2,2]`
- Linux　：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=13 fig0.typeCount=4 figCount=1 outFillRule=0 fig0.pts=[90,50,90,72.09139251708984,72.09139251708984,90,50,90,27.90860939025879,90,10,72.09139251708984,10,50,10,27.90860939025879,27.90860939025879,10,50,10,72.09139251708984,10,90,27.90860939025879,…] fig0.start=[90,50] fig0.types=[2,2,2,2]`
- 差异明细：
  - `fig0.start[0]: win=50 lin=90 (Δabs=40 Δrel=0.444)`
  - `fig0.start[1]: win=10 lin=50 (Δabs=40 Δrel=0.8)`
  - `fig0.pts[0]: win=50 lin=90 (Δabs=40 Δrel=0.444)`
  - `fig0.pts[1]: win=10 lin=50 (Δabs=40 Δrel=0.8)`
  - `fig0.pts[2]: win=72.09139251708984 lin=90 (Δabs=17.9 Δrel=0.199)`
  - `fig0.pts[3]: win=10 lin=72.09139251708984 (Δabs=62.1 Δrel=0.861)`
  - `fig0.pts[4]: win=90 lin=72.09139251708984 (Δabs=17.9 Δrel=0.199)`
  - `fig0.pts[5]: win=27.90860939025879 lin=90 (Δabs=62.1 Δrel=0.69)`
  - `fig0.pts[6]: win=90 lin=50 (Δabs=40 Δrel=0.444)`
  - `fig0.pts[7]: win=50 lin=90 (Δabs=40 Δrel=0.444)`
  - `fig0.pts[8]: win=90 lin=27.90860939025879 (Δabs=62.1 Δrel=0.69)`
  - `fig0.pts[9]: win=72.09139251708984 lin=90 (Δabs=17.9 Δrel=0.199)`

### `outline_circle_tol_10` — Reordered

- 意图：三个容差里若点数完全一样，说明 Outline 真的忽略容差
- 结论：几何等价，但至少一个图形的点序不同（环内旋转或反向）
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=13 fig0.typeCount=4 figCount=1 outFillRule=0 fig0.pts=[50,10,72.09139251708984,10,90,27.90860939025879,90,50,90,72.09139251708984,72.09139251708984,90,50,90,27.90860939025879,90,10,72.09139251708984,10,50,10,27.90860939025879,27.90860939025879,10,…] fig0.start=[50,10] fig0.types=[2,2,2,2]`
- Linux　：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=13 fig0.typeCount=4 figCount=1 outFillRule=0 fig0.pts=[90,50,90,72.09139251708984,72.09139251708984,90,50,90,27.90860939025879,90,10,72.09139251708984,10,50,10,27.90860939025879,27.90860939025879,10,50,10,72.09139251708984,10,90,27.90860939025879,…] fig0.start=[90,50] fig0.types=[2,2,2,2]`
- 差异明细：
  - `fig0.start[0]: win=50 lin=90 (Δabs=40 Δrel=0.444)`
  - `fig0.start[1]: win=10 lin=50 (Δabs=40 Δrel=0.8)`
  - `fig0.pts[0]: win=50 lin=90 (Δabs=40 Δrel=0.444)`
  - `fig0.pts[1]: win=10 lin=50 (Δabs=40 Δrel=0.8)`
  - `fig0.pts[2]: win=72.09139251708984 lin=90 (Δabs=17.9 Δrel=0.199)`
  - `fig0.pts[3]: win=10 lin=72.09139251708984 (Δabs=62.1 Δrel=0.861)`
  - `fig0.pts[4]: win=90 lin=72.09139251708984 (Δabs=17.9 Δrel=0.199)`
  - `fig0.pts[5]: win=27.90860939025879 lin=90 (Δabs=62.1 Δrel=0.69)`
  - `fig0.pts[6]: win=90 lin=50 (Δabs=40 Δrel=0.444)`
  - `fig0.pts[7]: win=50 lin=90 (Δabs=40 Δrel=0.444)`
  - `fig0.pts[8]: win=90 lin=27.90860939025879 (Δabs=62.1 Δrel=0.69)`
  - `fig0.pts[9]: win=72.09139251708984 lin=90 (Δabs=17.9 Δrel=0.199)`

### `outline_bowtie_evenodd` — Structural

- 意图：自交 + EvenOdd 消解
- 结论：输出键集合不同：lin 缺 [fig1.filled,fig1.closed,fig1.pointCount,fig1.typeCount,fig1.start,fig1.pts,fig1.types]
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=4 fig0.typeCount=3 fig1.closed=1 fig1.filled=1 fig1.pointCount=4 fig1.typeCount=3 figCount=2 outFillRule=0 fig0.pts=[20,0,20,20,10,10,20,0] fig0.start=[20,0] fig0.types=[1,1,1] fig1.pts=[0,0,10,10,0,20,0,0] fig1.start=[0,0] fig1.types=[1,1,1]`
- Linux　：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 figCount=1 outFillRule=0 fig0.pts=[0,0,20,20,20,0,0,20,0,0] fig0.start=[0,0] fig0.types=[1,1,1,1]`

### `outline_bowtie_nonzero` — Structural

- 意图：自交 + Nonzero 消解
- 结论：输出键集合不同：lin 缺 [fig1.filled,fig1.closed,fig1.pointCount,fig1.typeCount,fig1.start,fig1.pts,fig1.types]
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=4 fig0.typeCount=3 fig1.closed=1 fig1.filled=1 fig1.pointCount=4 fig1.typeCount=3 figCount=2 outFillRule=1 fig0.pts=[20,0,20,20,10,10,20,0] fig0.start=[20,0] fig0.types=[1,1,1] fig1.pts=[0,0,10,10,0,20,0,0] fig1.start=[0,0] fig1.types=[1,1,1]`
- Linux　：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 figCount=1 outFillRule=1 fig0.pts=[0,0,20,20,20,0,0,20,0,0] fig0.start=[0,0] fig0.types=[1,1,1,1]`

### `outline_nested_evenodd` — Reordered

- 意图：嵌套 EvenOdd
- 结论：几何等价，但至少一个图形的点序不同（环内旋转或反向）
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 fig1.closed=1 fig1.filled=1 fig1.pointCount=5 fig1.typeCount=4 figCount=2 outFillRule=0 fig0.pts=[20,20,20,80,80,80,80,20,20,20] fig0.start=[20,20] fig0.types=[1,1,1,1] fig1.pts=[0,0,100,0,100,100,0,100,0,0] fig1.start=[0,0] fig1.types=[1,1,1,1]`
- Linux　：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 fig1.closed=1 fig1.filled=1 fig1.pointCount=5 fig1.typeCount=4 figCount=2 outFillRule=0 fig0.pts=[0,0,100,0,100,100,0,100,0,0] fig0.start=[0,0] fig0.types=[1,1,1,1] fig1.pts=[20,20,80,20,80,80,20,80,20,20] fig1.start=[20,20] fig1.types=[1,1,1,1]`
- 差异明细：
  - `fig0.start[0]: win=20 lin=0 (Δabs=20 Δrel=1)`
  - `fig0.start[1]: win=20 lin=0 (Δabs=20 Δrel=1)`
  - `fig0.pts[0]: win=20 lin=0 (Δabs=20 Δrel=1)`
  - `fig0.pts[1]: win=20 lin=0 (Δabs=20 Δrel=1)`
  - `fig0.pts[2]: win=20 lin=100 (Δabs=80 Δrel=0.8)`
  - `fig0.pts[3]: win=80 lin=0 (Δabs=80 Δrel=1)`
  - `fig0.pts[4]: win=80 lin=100 (Δabs=20 Δrel=0.2)`
  - `fig0.pts[5]: win=80 lin=100 (Δabs=20 Δrel=0.2)`
  - `fig0.pts[6]: win=80 lin=0 (Δabs=80 Δrel=1)`
  - `fig0.pts[7]: win=20 lin=100 (Δabs=80 Δrel=0.8)`
  - `fig0.pts[8]: win=20 lin=0 (Δabs=20 Δrel=1)`
  - `fig0.pts[9]: win=20 lin=0 (Δabs=20 Δrel=1)`

### `outline_nested_nonzero` — Structural

- 意图：嵌套 Nonzero
- 结论：输出键集合不同：win 缺 [fig1.filled,fig1.closed,fig1.pointCount,fig1.typeCount,fig1.start,fig1.pts,fig1.types] 
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 figCount=1 outFillRule=1 fig0.pts=[0,0,100,0,100,100,0,100,0,0] fig0.start=[0,0] fig0.types=[1,1,1,1]`
- Linux　：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 fig1.closed=1 fig1.filled=1 fig1.pointCount=5 fig1.typeCount=4 figCount=2 outFillRule=1 fig0.pts=[0,0,100,0,100,100,0,100,0,0] fig0.start=[0,0] fig0.types=[1,1,1,1] fig1.pts=[20,20,80,20,80,80,20,80,20,20] fig1.start=[20,20] fig1.types=[1,1,1,1]`

### `outline_relative_true` — Reordered

- 意图：fRelative=true
- 结论：几何等价，但至少一个图形的点序不同（环内旋转或反向）
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=13 fig0.typeCount=4 figCount=1 outFillRule=0 fig0.pts=[50,10,72.09139251708984,10,90,27.90860939025879,90,50,90,72.09139251708984,72.09139251708984,90,50,90,27.90860939025879,90,10,72.09139251708984,10,50,10,27.90860939025879,27.90860939025879,10,…] fig0.start=[50,10] fig0.types=[2,2,2,2]`
- Linux　：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=13 fig0.typeCount=4 figCount=1 outFillRule=0 fig0.pts=[90,50,90,72.09139251708984,72.09139251708984,90,50,90,27.90860939025879,90,10,72.09139251708984,10,50,10,27.90860939025879,27.90860939025879,10,50,10,72.09139251708984,10,90,27.90860939025879,…] fig0.start=[90,50] fig0.types=[2,2,2,2]`
- 差异明细：
  - `fig0.start[0]: win=50 lin=90 (Δabs=40 Δrel=0.444)`
  - `fig0.start[1]: win=10 lin=50 (Δabs=40 Δrel=0.8)`
  - `fig0.pts[0]: win=50 lin=90 (Δabs=40 Δrel=0.444)`
  - `fig0.pts[1]: win=10 lin=50 (Δabs=40 Δrel=0.8)`
  - `fig0.pts[2]: win=72.09139251708984 lin=90 (Δabs=17.9 Δrel=0.199)`
  - `fig0.pts[3]: win=10 lin=72.09139251708984 (Δabs=62.1 Δrel=0.861)`
  - `fig0.pts[4]: win=90 lin=72.09139251708984 (Δabs=17.9 Δrel=0.199)`
  - `fig0.pts[5]: win=27.90860939025879 lin=90 (Δabs=62.1 Δrel=0.69)`
  - `fig0.pts[6]: win=90 lin=50 (Δabs=40 Δrel=0.444)`
  - `fig0.pts[7]: win=50 lin=90 (Δabs=40 Δrel=0.444)`
  - `fig0.pts[8]: win=90 lin=27.90860939025879 (Δabs=62.1 Δrel=0.69)`
  - `fig0.pts[9]: win=72.09139251708984 lin=90 (Δabs=17.9 Δrel=0.199)`

### `widen_rect_pen2` — Structural

- 意图：笔宽 2、斜接、平头
- 结论：输出键集合不同：win 缺 [fig1.filled,fig1.closed,fig1.pointCount,fig1.typeCount,fig1.start,fig1.pts,fig1.types] 
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=24 fig0.typeCount=23 figCount=1 outFillRule=1592590337 fig0.pts=[0,1,0,-1,100,-1,101,-1,101,100,101,101,0,101,-1,101,-1,0,-1,-1,0,-1,1,0,…] fig0.start=[0,1] fig0.types=[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]`
- Linux　：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 fig1.closed=1 fig1.filled=1 fig1.pointCount=5 fig1.typeCount=4 figCount=2 outFillRule=0 fig0.pts=[-1,-1,101,-1,101,101,-1,101,-1,-1] fig0.start=[-1,-1] fig0.types=[1,1,1,1] fig1.pts=[1,1,1,99,99,99,99,1,1,1] fig1.start=[1,1] fig1.types=[1,1,1,1]`

### `widen_rect_pen2_round` — Structural

- 意图：笔宽 2、圆角圆头
- 结论：输出键集合不同：win 缺 [fig1.filled,fig1.closed,fig1.pointCount,fig1.typeCount,fig1.start,fig1.pts,fig1.types] 
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=31 fig0.typeCount=22 figCount=1 outFillRule=1592590337 fig0.pts=[0,1,0,-1,100,-1,100.55228424072266,-1,101,-0.5522847771644592,101,0,101,100,101,100.55228424072266,100.55228424072266,101,100,101,0,101,-0.5522847771644592,101,…] fig0.start=[0,1] fig0.types=[1,1,2,1,2,1,2,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1]`
- Linux　：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=17 fig0.typeCount=8 fig1.closed=1 fig1.filled=1 fig1.pointCount=5 fig1.typeCount=4 figCount=2 outFillRule=0 fig0.pts=[-1,100,-1,0,-1,-0.2761423587799072,-0.2761423587799072,-1,0,-1,100,-1,100.2761459350586,-1,101,-0.2761423587799072,101,0,101,100,101,100.2761459350586,100.2761459350586,101,…] fig0.start=[-1,100] fig0.types=[1,2,1,2,1,2,1,2] fig1.pts=[1,1,1,99,99,99,99,1,1,1] fig1.start=[1,1] fig1.types=[1,1,1,1]`

### `widen_rect_pen2_bevel` — Structural

- 意图：笔宽 2、斜角、方头
- 结论：输出键集合不同：win 缺 [fig1.filled,fig1.closed,fig1.pointCount,fig1.typeCount,fig1.start,fig1.pts,fig1.types] 
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=23 fig0.typeCount=22 figCount=1 outFillRule=1592590337 fig0.pts=[0,1,0,-1,100,-1,101,0,101,100,100,101,0,101,-1,100,-1,0,0,-1,1,0,0,0,…] fig0.start=[0,1] fig0.types=[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]`
- Linux　：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=9 fig0.typeCount=8 fig1.closed=1 fig1.filled=1 fig1.pointCount=5 fig1.typeCount=4 figCount=2 outFillRule=0 fig0.pts=[0,-1,100,-1,101,0,101,100,100,101,0,101,-1,100,-1,0,0,-1] fig0.start=[0,-1] fig0.types=[1,1,1,1,1,1,1,1] fig1.pts=[1,1,1,99,99,99,99,1,1,1] fig1.start=[1,1] fig1.types=[1,1,1,1]`

### `widen_open_line_pen2` — Reordered

- 意图：开放线段：平头 → 一个矩形
- 结论：几何等价，但至少一个图形的点序不同（环内旋转或反向）
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 figCount=1 outFillRule=1592590337 fig0.pts=[0,1,0,-1,50,-1,50,1,0,1] fig0.start=[0,1] fig0.types=[1,1,1,1]`
- Linux　：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 figCount=1 outFillRule=0 fig0.pts=[0,-1,50,-1,50,1,0,1,0,-1] fig0.start=[0,-1] fig0.types=[1,1,1,1]`
- 差异明细：
  - `fig0.start[1]: win=1 lin=-1 (Δabs=2 Δrel=2)`
  - `fig0.pts[1]: win=1 lin=-1 (Δabs=2 Δrel=2)`
  - `fig0.pts[2]: win=0 lin=50 (Δabs=50 Δrel=1)`
  - `fig0.pts[5]: win=-1 lin=1 (Δabs=2 Δrel=2)`
  - `fig0.pts[6]: win=50 lin=0 (Δabs=50 Δrel=1)`
  - `fig0.pts[9]: win=1 lin=-1 (Δabs=2 Δrel=2)`

### `widen_open_line_pen2_round` — Deviation

- 意图：开放线段：圆头 → 带半圆端
- 结论：首个数值差异：fig0.start[1]: win=1 lin=-1 (Δabs=2 Δrel=2)（共 32 处）
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=15 fig0.typeCount=6 figCount=1 outFillRule=1592590337 fig0.pts=[0,1,-0.5522847771644592,1,-1,0.5522847771644592,-1,0,-1,-0.5522847771644592,-0.5522847771644592,-1,0,-1,50,-1,50.552284240722656,-1,51,-0.5522847771644592,51,0,51,0.5522847771644592,…] fig0.start=[0,1] fig0.types=[2,2,1,2,2,1]`
- Linux　：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=15 fig0.typeCount=6 figCount=1 outFillRule=0 fig0.pts=[0,-1,50,-1,50.27614212036133,-1,51,-0.2761423587799072,51,0,51,0.2761423587799072,50.27614212036133,1,50,1,0,1,-0.2761423587799072,1,-1,0.2761423587799072,-1,0,…] fig0.start=[0,-1] fig0.types=[1,2,2,1,2,2]`
- 差异明细：
  - `fig0.start[1]: win=1 lin=-1 (Δabs=2 Δrel=2)`
  - `fig0.pts[1]: win=1 lin=-1 (Δabs=2 Δrel=2)`
  - `fig0.pts[2]: win=-0.5522847771644592 lin=50 (Δabs=50.6 Δrel=1.01)`
  - `fig0.pts[3]: win=1 lin=-1 (Δabs=2 Δrel=2)`
  - `fig0.pts[4]: win=-1 lin=50.27614212036133 (Δabs=51.3 Δrel=1.02)`
  - `fig0.pts[5]: win=0.5522847771644592 lin=-1 (Δabs=1.55 Δrel=1.55)`
  - `fig0.pts[6]: win=-1 lin=51 (Δabs=52 Δrel=1.02)`
  - `fig0.pts[7]: win=0 lin=-0.2761423587799072 (Δabs=0.276 Δrel=1)`
  - `fig0.pts[8]: win=-1 lin=51 (Δabs=52 Δrel=1.02)`
  - `fig0.pts[9]: win=-0.5522847771644592 lin=0 (Δabs=0.552 Δrel=1)`
  - `fig0.pts[10]: win=-0.5522847771644592 lin=51 (Δabs=51.6 Δrel=1.01)`
  - `fig0.pts[11]: win=-1 lin=0.2761423587799072 (Δabs=1.28 Δrel=1.28)`

### `widen_open_line_pen2_square` — Structural

- 意图：开放线段：方头
- 结论：fig0.pts 长度不同：win=18 lin=12
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=9 fig0.typeCount=8 figCount=1 outFillRule=1592590337 fig0.pts=[-1,1,-1,-1,0,-1,50,-1,51,-1,51,1,50,1,0,1,-1,1] fig0.start=[-1,1] fig0.types=[1,1,1,1,1,1,1,1]`
- Linux　：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=6 fig0.typeCount=5 figCount=1 outFillRule=0 fig0.pts=[0,-1,51,-1,51,1,-1,1,-1,-1,0,-1] fig0.start=[0,-1] fig0.types=[1,1,1,1,1]`
- 差异明细：
  - `fig0.pointCount: win=9 lin=6 (Δabs=3 Δrel=0.333)`
  - `fig0.typeCount: win=8 lin=5 (Δabs=3 Δrel=0.375)`
  - `fig0.start[0]: win=-1 lin=0 (Δabs=1 Δrel=1)`
  - `fig0.start[1]: win=1 lin=-1 (Δabs=2 Δrel=2)`

### `widen_dash` — Structural

- 意图：虚线：dash 数组是相对笔宽的比例
- 结论：fig0.pts 长度不同：win=10 lin=8
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 fig1.closed=1 fig1.filled=1 fig1.pointCount=5 fig1.typeCount=4 fig2.closed=1 fig2.filled=1 fig2.pointCount=5 fig2.typeCount=4 fig3.closed=1 fig3.filled=1 fig3.pointCount=5 fig3.typeCount=4 fig4.closed=1 fig4.filled=1 fig4.pointCount=5 fig4.typeCount=4 figCount=5 outFillRule=1592590337 fig0.pts=[0,2,0,-2,8,-2,8,2,0,2] fig0.start=[0,2] fig0.types=[1,1,1,1] fig1.pts=[12,2,12,-2,20,-2,20,2,12,2] fig1.start=[12,2] fig1.types=[1,1,1,1] fig2.pts=[24,2,24,-2,32,-2,32,2,24,2] fig2.start=[24,2] fig2.types=[1,1,1,1] fig3.pts=[36,2,36,-2,44,-2,44,2,36,2] fig3.start=[36,2] fig3.types=[1,1,1,1] fig4.pts=[48,2,48,-2,50,-2,50,2,48,2] fig4.start=[48,2] fig4.types=[1,1,1,1]`
- Linux　：`hr=0x00000000 fig0.closed=0 fig0.filled=1 fig0.pointCount=4 fig0.typeCount=3 fig1.closed=0 fig1.filled=1 fig1.pointCount=4 fig1.typeCount=3 fig2.closed=0 fig2.filled=1 fig2.pointCount=4 fig2.typeCount=3 fig3.closed=0 fig3.filled=1 fig3.pointCount=4 fig3.typeCount=3 fig4.closed=0 fig4.filled=1 fig4.pointCount=4 fig4.typeCount=3 figCount=5 outFillRule=0 fig0.pts=[0,-2,8,-2,8,2,0,2] fig0.start=[0,-2] fig0.types=[1,1,1] fig1.pts=[12,-2,20,-2,20,2,12,2] fig1.start=[12,-2] fig1.types=[1,1,1] fig2.pts=[24,-2,32,-2,32,2,24,2] fig2.start=[24,-2] fig2.types=[1,1,1] fig3.pts=[36,-2,44,-2,44,2,36,2] fig3.start=[36,-2] fig3.types=[1,1,1] fig4.pts=[48,-2,50,-2,50,2,48,2] fig4.start=[48,-2] fig4.types=[1,1,1]`
- 差异明细：
  - `fig0.closed: win=1 lin=0 (Δabs=1 Δrel=1)`
  - `fig0.pointCount: win=5 lin=4 (Δabs=1 Δrel=0.2)`
  - `fig0.typeCount: win=4 lin=3 (Δabs=1 Δrel=0.25)`
  - `fig1.closed: win=1 lin=0 (Δabs=1 Δrel=1)`
  - `fig1.pointCount: win=5 lin=4 (Δabs=1 Δrel=0.2)`
  - `fig1.typeCount: win=4 lin=3 (Δabs=1 Δrel=0.25)`
  - `fig2.closed: win=1 lin=0 (Δabs=1 Δrel=1)`
  - `fig2.pointCount: win=5 lin=4 (Δabs=1 Δrel=0.2)`
  - `fig2.typeCount: win=4 lin=3 (Δabs=1 Δrel=0.25)`
  - `fig3.closed: win=1 lin=0 (Δabs=1 Δrel=1)`
  - `fig3.pointCount: win=5 lin=4 (Δabs=1 Δrel=0.2)`
  - `fig3.typeCount: win=4 lin=3 (Δabs=1 Δrel=0.25)`

### `widen_dash_offset` — Structural

- 意图：虚线 + DashOffset
- 结论：fig0.pts 长度不同：win=10 lin=8
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 fig1.closed=1 fig1.filled=1 fig1.pointCount=5 fig1.typeCount=4 fig2.closed=1 fig2.filled=1 fig2.pointCount=5 fig2.typeCount=4 fig3.closed=1 fig3.filled=1 fig3.pointCount=5 fig3.typeCount=4 fig4.closed=1 fig4.filled=1 fig4.pointCount=5 fig4.typeCount=4 figCount=5 outFillRule=1592590337 fig0.pts=[0,2,0,-2,6,-2,6,2,0,2] fig0.start=[0,2] fig0.types=[1,1,1,1] fig1.pts=[10,2,10,-2,18,-2,18,2,10,2] fig1.start=[10,2] fig1.types=[1,1,1,1] fig2.pts=[22,2,22,-2,30,-2,30,2,22,2] fig2.start=[22,2] fig2.types=[1,1,1,1] fig3.pts=[34,2,34,-2,42,-2,42,2,34,2] fig3.start=[34,2] fig3.types=[1,1,1,1] fig4.pts=[46,2,46,-2,50,-2,50,2,46,2] fig4.start=[46,2] fig4.types=[1,1,1,1]`
- Linux　：`hr=0x00000000 fig0.closed=0 fig0.filled=1 fig0.pointCount=4 fig0.typeCount=3 fig1.closed=0 fig1.filled=1 fig1.pointCount=4 fig1.typeCount=3 fig2.closed=0 fig2.filled=1 fig2.pointCount=4 fig2.typeCount=3 fig3.closed=0 fig3.filled=1 fig3.pointCount=4 fig3.typeCount=3 fig4.closed=0 fig4.filled=1 fig4.pointCount=4 fig4.typeCount=3 figCount=5 outFillRule=0 fig0.pts=[0,-2,7.5,-2,7.5,2,0,2] fig0.start=[0,-2] fig0.types=[1,1,1] fig1.pts=[11.5,-2,19.5,-2,19.5,2,11.5,2] fig1.start=[11.5,-2] fig1.types=[1,1,1] fig2.pts=[23.5,-2,31.5,-2,31.5,2,23.5,2] fig2.start=[23.5,-2] fig2.types=[1,1,1] fig3.pts=[35.5,-2,43.5,-2,43.5,2,35.5,2] fig3.start=[35.5,-2] fig3.types=[1,1,1] fig4.pts=[47.5,-2,50,-2,50,2,47.5,2] fig4.start=[47.5,-2] fig4.types=[1,1,1]`
- 差异明细：
  - `fig0.closed: win=1 lin=0 (Δabs=1 Δrel=1)`
  - `fig0.pointCount: win=5 lin=4 (Δabs=1 Δrel=0.2)`
  - `fig0.typeCount: win=4 lin=3 (Δabs=1 Δrel=0.25)`
  - `fig1.closed: win=1 lin=0 (Δabs=1 Δrel=1)`
  - `fig1.pointCount: win=5 lin=4 (Δabs=1 Δrel=0.2)`
  - `fig1.typeCount: win=4 lin=3 (Δabs=1 Δrel=0.25)`
  - `fig2.closed: win=1 lin=0 (Δabs=1 Δrel=1)`
  - `fig2.pointCount: win=5 lin=4 (Δabs=1 Δrel=0.2)`
  - `fig2.typeCount: win=4 lin=3 (Δabs=1 Δrel=0.25)`
  - `fig3.closed: win=1 lin=0 (Δabs=1 Δrel=1)`
  - `fig3.pointCount: win=5 lin=4 (Δabs=1 Δrel=0.2)`
  - `fig3.typeCount: win=4 lin=3 (Δabs=1 Δrel=0.25)`

### `widen_dash_identity_matrix` — Structural

- 意图：★ 显式给单位矩阵：真机在不给矩阵时**不做虚线**（见报告），这里验证是否与矩阵参数有关
- 结论：fig0.pts 长度不同：win=10 lin=8
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 fig1.closed=1 fig1.filled=1 fig1.pointCount=5 fig1.typeCount=4 fig2.closed=1 fig2.filled=1 fig2.pointCount=5 fig2.typeCount=4 fig3.closed=1 fig3.filled=1 fig3.pointCount=5 fig3.typeCount=4 fig4.closed=1 fig4.filled=1 fig4.pointCount=5 fig4.typeCount=4 figCount=5 outFillRule=1592590337 fig0.pts=[0,2,0,-2,8,-2,8,2,0,2] fig0.start=[0,2] fig0.types=[1,1,1,1] fig1.pts=[12,2,12,-2,20,-2,20,2,12,2] fig1.start=[12,2] fig1.types=[1,1,1,1] fig2.pts=[24,2,24,-2,32,-2,32,2,24,2] fig2.start=[24,2] fig2.types=[1,1,1,1] fig3.pts=[36,2,36,-2,44,-2,44,2,36,2] fig3.start=[36,2] fig3.types=[1,1,1,1] fig4.pts=[48,2,48,-2,50,-2,50,2,48,2] fig4.start=[48,2] fig4.types=[1,1,1,1]`
- Linux　：`hr=0x00000000 fig0.closed=0 fig0.filled=1 fig0.pointCount=4 fig0.typeCount=3 fig1.closed=0 fig1.filled=1 fig1.pointCount=4 fig1.typeCount=3 fig2.closed=0 fig2.filled=1 fig2.pointCount=4 fig2.typeCount=3 fig3.closed=0 fig3.filled=1 fig3.pointCount=4 fig3.typeCount=3 fig4.closed=0 fig4.filled=1 fig4.pointCount=4 fig4.typeCount=3 figCount=5 outFillRule=0 fig0.pts=[0,-2,8,-2,8,2,0,2] fig0.start=[0,-2] fig0.types=[1,1,1] fig1.pts=[12,-2,20,-2,20,2,12,2] fig1.start=[12,-2] fig1.types=[1,1,1] fig2.pts=[24,-2,32,-2,32,2,24,2] fig2.start=[24,-2] fig2.types=[1,1,1] fig3.pts=[36,-2,44,-2,44,2,36,2] fig3.start=[36,-2] fig3.types=[1,1,1] fig4.pts=[48,-2,50,-2,50,2,48,2] fig4.start=[48,-2] fig4.types=[1,1,1]`
- 差异明细：
  - `fig0.closed: win=1 lin=0 (Δabs=1 Δrel=1)`
  - `fig0.pointCount: win=5 lin=4 (Δabs=1 Δrel=0.2)`
  - `fig0.typeCount: win=4 lin=3 (Δabs=1 Δrel=0.25)`
  - `fig1.closed: win=1 lin=0 (Δabs=1 Δrel=1)`
  - `fig1.pointCount: win=5 lin=4 (Δabs=1 Δrel=0.2)`
  - `fig1.typeCount: win=4 lin=3 (Δabs=1 Δrel=0.25)`
  - `fig2.closed: win=1 lin=0 (Δabs=1 Δrel=1)`
  - `fig2.pointCount: win=5 lin=4 (Δabs=1 Δrel=0.2)`
  - `fig2.typeCount: win=4 lin=3 (Δabs=1 Δrel=0.25)`
  - `fig3.closed: win=1 lin=0 (Δabs=1 Δrel=1)`
  - `fig3.pointCount: win=5 lin=4 (Δabs=1 Δrel=0.2)`
  - `fig3.typeCount: win=4 lin=3 (Δabs=1 Δrel=0.25)`

### `widen_dash_scale_matrix` — Structural

- 意图：★ 虚线 + 缩放矩阵
- 结论：fig0.pts 长度不同：win=10 lin=8
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 fig1.closed=1 fig1.filled=1 fig1.pointCount=5 fig1.typeCount=4 fig2.closed=1 fig2.filled=1 fig2.pointCount=5 fig2.typeCount=4 fig3.closed=1 fig3.filled=1 fig3.pointCount=5 fig3.typeCount=4 fig4.closed=1 fig4.filled=1 fig4.pointCount=5 fig4.typeCount=4 fig5.closed=1 fig5.filled=1 fig5.pointCount=5 fig5.typeCount=4 fig6.closed=1 fig6.filled=1 fig6.pointCount=5 fig6.typeCount=4 fig7.closed=1 fig7.filled=1 fig7.pointCount=5 fig7.typeCount=4 fig8.closed=1 fig8.filled=1 fig8.pointCount=5 fig8.typeCount=4 figCount=9 outFillRule=1592590337 fig0.pts=[0,2,0,-2,8,-2,8,2,0,2] fig0.start=[0,2] fig0.types=[1,1,1,1] fig1.pts=[12,2,12,-2,20,-2,20,2,12,2] fig1.start=[12,2] fig1.types=[1,1,1,1] fig2.pts=[24,2,24,-2,32,-2,32,2,24,2] fig2.start=[24,2] fig2.types=[1,1,1,1] fig3.pts=[36,2,36,-2,44,-2,44,2,36,2] fig3.start=[36,2] fig3.types=[1,1,1,1] fig4.pts=[48,2,48,-2,56,-2,56,2,48,2] fig4.start=[48,2] fig4.types=[1,1,1,1] fig5.pts=[60,2,60,-2,68,-2,68,2,60,2] fig5.start=[60,2] fig5.types=[1,1,1,1] fig6.pts=[72,2,72,-2,80,-2,80,2,72,2] fig6.start=[72,2] fig6.types=[1,1,1,1] fig7.pts=[84,2,84,-2,92,-2,92,2,84,2] fig7.start=[84,2] fig7.types=[1,1,1,1] fig8.pts=[96,2,96,-2,100,-2,100,2,96,2] fig8.start=[96,2] fig8.types=[1,1,1,1]`
- Linux　：`hr=0x00000000 fig0.closed=0 fig0.filled=1 fig0.pointCount=4 fig0.typeCount=3 fig1.closed=0 fig1.filled=1 fig1.pointCount=4 fig1.typeCount=3 fig2.closed=0 fig2.filled=1 fig2.pointCount=4 fig2.typeCount=3 fig3.closed=0 fig3.filled=1 fig3.pointCount=4 fig3.typeCount=3 fig4.closed=0 fig4.filled=1 fig4.pointCount=4 fig4.typeCount=3 fig5.closed=0 fig5.filled=1 fig5.pointCount=4 fig5.typeCount=3 fig6.closed=0 fig6.filled=1 fig6.pointCount=4 fig6.typeCount=3 fig7.closed=0 fig7.filled=1 fig7.pointCount=4 fig7.typeCount=3 fig8.closed=0 fig8.filled=1 fig8.pointCount=4 fig8.typeCount=3 figCount=9 outFillRule=0 fig0.pts=[0,-2,8,-2,8,2,0,2] fig0.start=[0,-2] fig0.types=[1,1,1] fig1.pts=[12,-2,20,-2,20,2,12,2] fig1.start=[12,-2] fig1.types=[1,1,1] fig2.pts=[24,-2,32,-2,32,2,24,2] fig2.start=[24,-2] fig2.types=[1,1,1] fig3.pts=[36,-2,44,-2,44,2,36,2] fig3.start=[36,-2] fig3.types=[1,1,1] fig4.pts=[48,-2,56,-2,56,2,48,2] fig4.start=[48,-2] fig4.types=[1,1,1] fig5.pts=[60,-2,68,-2,68,2,60,2] fig5.start=[60,-2] fig5.types=[1,1,1] fig6.pts=[72,-2,80,-2,80,2,72,2] fig6.start=[72,-2] fig6.types=[1,1,1] fig7.pts=[84,-2,92,-2,92,2,84,2] fig7.start=[84,-2] fig7.types=[1,1,1] fig8.pts=[96,-2,100,-2,100,2,96,2] fig8.start=[96,-2] fig8.types=[1,1,1]`
- 差异明细：
  - `fig0.closed: win=1 lin=0 (Δabs=1 Δrel=1)`
  - `fig0.pointCount: win=5 lin=4 (Δabs=1 Δrel=0.2)`
  - `fig0.typeCount: win=4 lin=3 (Δabs=1 Δrel=0.25)`
  - `fig1.closed: win=1 lin=0 (Δabs=1 Δrel=1)`
  - `fig1.pointCount: win=5 lin=4 (Δabs=1 Δrel=0.2)`
  - `fig1.typeCount: win=4 lin=3 (Δabs=1 Δrel=0.25)`
  - `fig2.closed: win=1 lin=0 (Δabs=1 Δrel=1)`
  - `fig2.pointCount: win=5 lin=4 (Δabs=1 Δrel=0.2)`
  - `fig2.typeCount: win=4 lin=3 (Δabs=1 Δrel=0.25)`
  - `fig3.closed: win=1 lin=0 (Δabs=1 Δrel=1)`
  - `fig3.pointCount: win=5 lin=4 (Δabs=1 Δrel=0.2)`
  - `fig3.typeCount: win=4 lin=3 (Δabs=1 Δrel=0.25)`

### `widen_dashed_rect` — Structural

- 意图：★ 闭合图形的虚线
- 结论：输出键集合不同：lin 缺 [fig66.filled,fig66.closed,fig66.pointCount,fig66.typeCount,fig66.start,fig66.pts,fig66.types]
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 fig1.closed=1 fig1.filled=1 fig1.pointCount=5 fig1.typeCount=4 fig10.closed=1 fig10.filled=1 fig10.pointCount=5 fig10.typeCount=4 fig11.closed=1 fig11.filled=1 fig11.pointCount=5 fig11.typeCount=4 fig12.closed=1 fig12.filled=1 fig12.pointCount=5 fig12.typeCount=4 fig13.closed=1 fig13.filled=1 fig13.pointCount=5 fig13.typeCount=4 fig14.closed=1 fig14.filled=1 fig14.pointCount=5 fig14.typeCount=4 fig15.closed=1 fig15.filled=1 fig15.pointCount=5 fig15.typeCount=4 fig16.closed=1 fig16.filled=1 fig16.pointCount=7 fig16.typeCount=6 fig17.closed=1 fig17.filled=1 fig17.pointCount=5 fig17.typeCount=4 fig18.closed=1 fig18.filled=1 fig18.pointCount=5 fig18.typeCount=4 fig19.closed=1 fig19.filled=1 fig19.pointCount=5 fig19.typeCount=4 fig2.closed=1 fig2.filled=1 fig2.pointCount=5 fig2.typeCount=4 fig20.closed=1 fig20.filled=1 fig20.pointCount=5 fig20.typeCount=4 fig21.closed=1 fig21.filled=1 fig21.pointCount=5 fig21.typeCount=4 fig22.closed=1 fig22.filled=1 fig22.pointCount=5 fig22.typeCount=4 fig23.closed=1 fig23.filled=1 fig23.pointCount=5 fig23.typeCount=4 fig24.closed=1 fig24.filled=1 fig24.pointCount=5 fig24.typeCount=4 fig25.closed=1 fig25.filled=1 fig25.pointCount=5 fig25.typeCount=4 fig26.closed=1 fig26.filled=1 fig26.pointCount=5 fig26.typeCount=4 fig27.closed=1 fig27.filled=1 fig27.pointCount=5 fig27.typeCount=4 fig28.closed=1 fig28.filled=1 fig28.pointCount=5 fig28.typeCount=4 fig29.closed=1 fig29.filled=1 fig29.pointCount=5 fig29.typeCount=4 fig3.closed=1 fig3.filled=1 fig3.pointCount=5 fig3.typeCount=4 fig30.closed=1 fig30.filled=1 fig30.pointCount=5 fig30.typeCount=4 fig31.closed=1 fig31.filled=1 fig31.pointCount=5 fig31.typeCount=4 fig32.closed=1 fig32.filled=1 fig32.pointCount=5 fig32.typeCount=4 fig33.closed=1 fig33.filled=1 fig33.pointCount=10 fig33.typeCount=9 fig34.closed=1 fig34.filled=1 fig34.pointCount=5 fig34.typeCount=4 fig35.closed=1 fig35.filled=1 fig35.pointCount=5 fig35.typeCount=4 fig36.closed=1 fig36.filled=1 fig36.pointCount=5 fig36.typeCount=4 fig37.closed=1 fig37.filled=1 fig37.pointCount=5 fig37.typeCount=4 fig38.closed=1 fig38.filled=1 fig38.pointCount=5 fig38.typeCount=4 fig39.closed=1 fig39.filled=1 fig39.pointCount=5 fig39.typeCount=4 fig4.closed=1 fig4.filled=1 fig4.pointCount=5 fig4.typeCount=4 fig40.closed=1 fig40.filled=1 fig40.pointCount=5 fig40.typeCount=4 fig41.closed=1 fig41.filled=1 fig41.pointCount=5 fig41.typeCount=4 fig42.closed=1 fig42.filled=1 fig42.pointCount=5 fig42.typeCount=4 fig43.closed=1 fig43.filled=1 fig43.pointCount=5 fig43.typeCount=4 fig44.closed=1 fig44.filled=1 fig44.pointCount=5 fig44.typeCount=4 fig45.closed=1 fig45.filled=1 fig45.pointCount=5 fig45.typeCount=4 fig46.closed=1 fig46.filled=1 fig46.pointCount=5 fig46.typeCount=4 fig47.closed=1 fig47.filled=1 fig47.pointCount=5 fig47.typeCount=4 fig48.closed=1 fig48.filled=1 fig48.pointCount=5 fig48.typeCount=4 fig49.closed=1 fig49.filled=1 fig49.pointCount=5 fig49.typeCount=4 fig5.closed=1 fig5.filled=1 fig5.pointCount=5 fig5.typeCount=4 fig50.closed=1 fig50.filled=1 fig50.pointCount=5 fig50.typeCount=4 fig51.closed=1 fig51.filled=1 fig51.pointCount=5 fig51.typeCount=4 fig52.closed=1 fig52.filled=1 fig52.pointCount=5 fig52.typeCount=4 fig53.closed=1 fig53.filled=1 fig53.pointCount=5 fig53.typeCount=4 fig54.closed=1 fig54.filled=1 fig54.pointCount=5 fig54.typeCount=4 fig55.closed=1 fig55.filled=1 fig55.pointCount=5 fig55.typeCount=4 fig56.closed=1 fig56.filled=1 fig56.pointCount=5 fig56.typeCount=4 fig57.closed=1 fig57.filled=1 fig57.pointCount=5 fig57.typeCount=4 fig58.closed=1 fig58.filled=1 fig58.pointCount=5 fig58.typeCount=4 fig59.closed=1 fig59.filled=1 fig59.pointCount=5 fig59.typeCount=4 fig6.closed=1 fig6.filled=1 fig6.pointCount=5 fig6.typeCount=4 fig60.closed=1 fig60.filled=1 fig60.pointCount=5 fig60.typeCount=4 fig61.closed=1 fig61.filled=1 fig61.pointCount=5 fig61.typeCount=4 fig62.closed=1 fig62.filled=1 fig62.pointCount=5 fig62.typeCount=4 fig63.closed=1 fig63.filled=1 fig63.pointCount=5 fig63.typeCount=4 fig64.closed=1 fig64.filled=1 fig64.pointCount=5 fig64.typeCount=4 fig65.closed=1 fig65.filled=1 fig65.pointCount=5 fig65.typeCount=4 fig66.closed=1 fig66.filled=1 fig66.pointCount=7 fig66.typeCount=6 fig7.closed=1 fig7.filled=1 fig7.pointCount=5 fig7.typeCount=4 fig8.closed=1 fig8.filled=1 fig8.pointCount=5 fig8.typeCount=4 fig9.closed=1 fig9.filled=1 fig9.pointCount=5 fig9.typeCount=4 figCount=67 outFillRule=1592590337 fig0.pts=[0,1,0,-1,4,-1,4,1,0,1] fig0.start=[0,1] fig0.types=[1,1,1,1] fig1.pts=[6,1,6,-1,10,-1,10,1,6,1] fig1.start=[6,1] fig1.types=[1,1,1,1] fig10.pts=[60,1,60,-1,64,-1,64,1,60,1] fig10.start=[60,1] fig10.types=[1,1,1,1] fig11.pts=[66,1,66,-1,70,-1,70,1,66,1] fig11.start=[66,1] fig11.types=[1,1,1,1] fig12.pts=[72,1,72,-1,76,-1,76,1,72,1] fig12.start=[72,1] fig12.types=[1,1,1,1] fig13.pts=[78,1,78,-1,82,-1,82,1,78,1] fig13.start=[78,1] fig13.types=[1,1,1,1] fig14.pts=[84,1,84,-1,88,-1,88,1,84,1] fig14.start=[84,1] fig14.types=[1,1,1,1] fig15.pts=[90,1,90,-1,94,-1,94,1,90,1] fig15.start=[90,1] fig15.types=[1,1,1,1] fig16.pts=[96,1,96,-1,100,-1,100,-1,100,1,100,1,96,1] fig16.start=[96,1] fig16.types=[1,1,1,1,1,1] fig17.pts=[99,2,101,2,101,6,99,6,99,2] fig17.start=[99,2] fig17.types=[1,1,1,1] fig18.pts=[99,8,101,8,101,12,99,12,99,8] fig18.start=[99,8] fig18.types=[1,1,1,1] fig19.pts=[99,14,101,14,101,18,99,18,99,14] fig19.start=[99,14] fig19.types=[1,1,1,1] fig2.pts=[12,1,12,-1,16,-1,16,1,12,1] fig2.start=[12,1] fig2.types=[1,1,1,1] fig20.pts=[99,20,101,20,101,24,99,24,99,20] fig20.start=[99,20] fig20.types=[1,1,1,1] fig21.pts=[99,26,101,26,101,30,99,30,99,26] fig21.start=[99,26] fig21.types=[1,1,1,1] fig22.pts=[99,32,101,32,101,36,99,36,99,32] fig22.start=[99,32] fig22.types=[1,1,1,1] fig23.pts=[99,38,101,38,101,42,99,42,99,38] fig23.start=[99,38] fig23.types=[1,1,1,1] fig24.pts=[99,44,101,44,101,48,99,48,99,44] fig24.start=[99,44] fig24.types=[1,1,1,1] fig25.pts=[99,50,101,50,101,54,99,54,99,50] fig25.start=[99,50] fig25.types=[1,1,1,1] fig26.pts=[99,56,101,56,101,60,99,60,99,56] fig26.start=[99,56] fig26.types=[1,1,1,1] fig27.pts=[99,62,101,62,101,66,99,66,99,62] fig27.start=[99,62] fig27.types=[1,1,1,1] fig28.pts=[99,68,101,68,101,72,99,72,99,68] fig28.start=[99,68] fig28.types=[1,1,1,1] fig29.pts=[99,74,101,74,101,78,99,78,99,74] fig29.start=[99,74] fig29.types=[1,1,1,1] fig3.pts=[18,1,18,-1,22,-1,22,1,18,1] fig3.start=[18,1] fig3.types=[1,1,1,1] fig30.pts=[99,80,101,80,101,84,99,84,99,80] fig30.start=[99,80] fig30.types=[1,1,1,1] fig31.pts=[99,86,101,86,101,90,99,90,99,86] fig31.start=[99,86] fig31.types=[1,1,1,1] fig32.pts=[99,92,101,92,101,96,99,96,99,92] fig32.start=[99,92] fig32.types=[1,1,1,1] fig33.pts=[99,98,101,98,101,100,101,101,98,101,98,99,100,99,100,100,99,100,99,98] fig33.start=[99,98] fig33.types=[1,1,1,1,1,1,1,1,1] fig34.pts=[96,99,96,101,92,101,92,99,96,99] fig34.start=[96,99] fig34.types=[1,1,1,1] fig35.pts=[90,99,90,101,86,101,86,99,90,99] fig35.start=[90,99] fig35.types=[1,1,1,1] fig36.pts=[84,99,84,101,80,101,80,99,84,99] fig36.start=[84,99] fig36.types=[1,1,1,1] fig37.pts=[78,99,78,101,74,101,74,99,78,99] fig37.start=[78,99] fig37.types=[1,1,1,1] fig38.pts=[72,99,72,101,68,101,68,99,72,99] fig38.start=[72,99] fig38.types=[1,1,1,1] fig39.pts=[66,99,66,101,62,101,62,99,66,99] fig39.start=[66,99] fig39.types=[1,1,1,1] fig4.pts=[24,1,24,-1,28,-1,28,1,24,1] fig4.start=[24,1] fig4.types=[1,1,1,1] fig40.pts=[60,99,60,101,56,101,56,99,60,99] fig40.start=[60,99] fig40.types=[1,1,1,1] fig41.pts=[54,99,54,101,50,101,50,99,54,99] fig41.start=[54,99] fig41.types=[1,1,1,1] fig42.pts=[48,99,48,101,44,101,44,99,48,99] fig42.start=[48,99] fig42.types=[1,1,1,1] fig43.pts=[42,99,42,101,38,101,38,99,42,99] fig43.start=[42,99] fig43.types=[1,1,1,1] fig44.pts=[36,99,36,101,32,101,32,99,36,99] fig44.start=[36,99] fig44.types=[1,1,1,1] fig45.pts=[30,99,30,101,26,101,26,99,30,99] fig45.start=[30,99] fig45.types=[1,1,1,1] fig46.pts=[24,99,24,101,20,101,20,99,24,99] fig46.start=[24,99] fig46.types=[1,1,1,1] fig47.pts=[18,99,18,101,14,101,14,99,18,99] fig47.start=[18,99] fig47.types=[1,1,1,1] fig48.pts=[12,99,12,101,8,101,8,99,12,99] fig48.start=[12,99] fig48.types=[1,1,1,1] fig49.pts=[6,99,6,101,2,101,2,99,6,99] fig49.start=[6,99] fig49.types=[1,1,1,1] fig5.pts=[30,1,30,-1,34,-1,34,1,30,1] fig5.start=[30,1] fig5.types=[1,1,1,1] fig50.pts=[1,100,-1,100,-1,96,1,96,1,100] fig50.start=[1,100] fig50.types=[1,1,1,1] fig51.pts=[1,94,-1,94,-1,90,1,90,1,94] fig51.start=[1,94] fig51.types=[1,1,1,1] fig52.pts=[1,88,-1,88,-1,84,1,84,1,88] fig52.start=[1,88] fig52.types=[1,1,1,1] fig53.pts=[1,82,-1,82,-1,78,1,78,1,82] fig53.start=[1,82] fig53.types=[1,1,1,1] fig54.pts=[1,76,-1,76,-1,72,1,72,1,76] fig54.start=[1,76] fig54.types=[1,1,1,1] fig55.pts=[1,70,-1,70,-1,66,1,66,1,70] fig55.start=[1,70] fig55.types=[1,1,1,1] fig56.pts=[1,64,-1,64,-1,60,1,60,1,64] fig56.start=[1,64] fig56.types=[1,1,1,1] fig57.pts=[1,58,-1,58,-1,54,1,54,1,58] fig57.start=[1,58] fig57.types=[1,1,1,1] fig58.pts=[1,52,-1,52,-1,48,1,48,1,52] fig58.start=[1,52] fig58.types=[1,1,1,1] fig59.pts=[1,46,-1,46,-1,42,1,42,1,46] fig59.start=[1,46] fig59.types=[1,1,1,1] fig6.pts=[36,1,36,-1,40,-1,40,1,36,1] fig6.start=[36,1] fig6.types=[1,1,1,1] fig60.pts=[1,40,-1,40,-1,36,1,36,1,40] fig60.start=[1,40] fig60.types=[1,1,1,1] fig61.pts=[1,34,-1,34,-1,30,1,30,1,34] fig61.start=[1,34] fig61.types=[1,1,1,1] fig62.pts=[1,28,-1,28,-1,24,1,24,1,28] fig62.start=[1,28] fig62.types=[1,1,1,1] fig63.pts=[1,22,-1,22,-1,18,1,18,1,22] fig63.start=[1,22] fig63.types=[1,1,1,1] fig64.pts=[1,16,-1,16,-1,12,1,12,1,16] fig64.start=[1,16] fig64.types=[1,1,1,1] fig65.pts=[1,10,-1,10,-1,6,1,6,1,10] fig65.start=[1,10] fig65.types=[1,1,1,1] fig66.pts=[1,4,-1,4,-1,0,-1,0,1,0,1,0,1,4] fig66.start=[1,4] fig66.types=[1,1,1,1,1,1] fig7.pts=[42,1,42,-1,46,-1,46,1,42,1] fig7.start=[42,1] fig7.types=[1,1,1,1] fig8.pts=[48,1,48,-1,52,-1,52,1,48,1] fig8.start=[48,1] fig8.types=[1,1,1,1] fig9.pts=[54,1,54,-1,58,-1,58,1,54,1] fig9.start=[54,1] fig9.types=[1,1,1,1]`
- Linux　：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 fig1.closed=1 fig1.filled=1 fig1.pointCount=5 fig1.typeCount=4 fig10.closed=1 fig10.filled=1 fig10.pointCount=5 fig10.typeCount=4 fig11.closed=1 fig11.filled=1 fig11.pointCount=5 fig11.typeCount=4 fig12.closed=1 fig12.filled=1 fig12.pointCount=5 fig12.typeCount=4 fig13.closed=1 fig13.filled=1 fig13.pointCount=5 fig13.typeCount=4 fig14.closed=1 fig14.filled=1 fig14.pointCount=5 fig14.typeCount=4 fig15.closed=1 fig15.filled=1 fig15.pointCount=5 fig15.typeCount=4 fig16.closed=1 fig16.filled=1 fig16.pointCount=5 fig16.typeCount=4 fig17.closed=1 fig17.filled=1 fig17.pointCount=5 fig17.typeCount=4 fig18.closed=1 fig18.filled=1 fig18.pointCount=5 fig18.typeCount=4 fig19.closed=1 fig19.filled=1 fig19.pointCount=5 fig19.typeCount=4 fig2.closed=1 fig2.filled=1 fig2.pointCount=5 fig2.typeCount=4 fig20.closed=1 fig20.filled=1 fig20.pointCount=5 fig20.typeCount=4 fig21.closed=1 fig21.filled=1 fig21.pointCount=5 fig21.typeCount=4 fig22.closed=1 fig22.filled=1 fig22.pointCount=5 fig22.typeCount=4 fig23.closed=1 fig23.filled=1 fig23.pointCount=5 fig23.typeCount=4 fig24.closed=1 fig24.filled=1 fig24.pointCount=5 fig24.typeCount=4 fig25.closed=1 fig25.filled=1 fig25.pointCount=5 fig25.typeCount=4 fig26.closed=1 fig26.filled=1 fig26.pointCount=5 fig26.typeCount=4 fig27.closed=1 fig27.filled=1 fig27.pointCount=5 fig27.typeCount=4 fig28.closed=1 fig28.filled=1 fig28.pointCount=5 fig28.typeCount=4 fig29.closed=1 fig29.filled=1 fig29.pointCount=5 fig29.typeCount=4 fig3.closed=1 fig3.filled=1 fig3.pointCount=5 fig3.typeCount=4 fig30.closed=1 fig30.filled=1 fig30.pointCount=5 fig30.typeCount=4 fig31.closed=1 fig31.filled=1 fig31.pointCount=5 fig31.typeCount=4 fig32.closed=1 fig32.filled=1 fig32.pointCount=9 fig32.typeCount=8 fig33.closed=1 fig33.filled=1 fig33.pointCount=5 fig33.typeCount=4 fig34.closed=1 fig34.filled=1 fig34.pointCount=5 fig34.typeCount=4 fig35.closed=1 fig35.filled=1 fig35.pointCount=5 fig35.typeCount=4 fig36.closed=1 fig36.filled=1 fig36.pointCount=5 fig36.typeCount=4 fig37.closed=1 fig37.filled=1 fig37.pointCount=5 fig37.typeCount=4 fig38.closed=1 fig38.filled=1 fig38.pointCount=5 fig38.typeCount=4 fig39.closed=1 fig39.filled=1 fig39.pointCount=5 fig39.typeCount=4 fig4.closed=1 fig4.filled=1 fig4.pointCount=5 fig4.typeCount=4 fig40.closed=1 fig40.filled=1 fig40.pointCount=5 fig40.typeCount=4 fig41.closed=1 fig41.filled=1 fig41.pointCount=5 fig41.typeCount=4 fig42.closed=1 fig42.filled=1 fig42.pointCount=5 fig42.typeCount=4 fig43.closed=1 fig43.filled=1 fig43.pointCount=5 fig43.typeCount=4 fig44.closed=1 fig44.filled=1 fig44.pointCount=5 fig44.typeCount=4 fig45.closed=1 fig45.filled=1 fig45.pointCount=5 fig45.typeCount=4 fig46.closed=1 fig46.filled=1 fig46.pointCount=5 fig46.typeCount=4 fig47.closed=1 fig47.filled=1 fig47.pointCount=5 fig47.typeCount=4 fig48.closed=1 fig48.filled=1 fig48.pointCount=5 fig48.typeCount=4 fig49.closed=1 fig49.filled=1 fig49.pointCount=5 fig49.typeCount=4 fig5.closed=1 fig5.filled=1 fig5.pointCount=5 fig5.typeCount=4 fig50.closed=1 fig50.filled=1 fig50.pointCount=5 fig50.typeCount=4 fig51.closed=1 fig51.filled=1 fig51.pointCount=5 fig51.typeCount=4 fig52.closed=1 fig52.filled=1 fig52.pointCount=5 fig52.typeCount=4 fig53.closed=1 fig53.filled=1 fig53.pointCount=5 fig53.typeCount=4 fig54.closed=1 fig54.filled=1 fig54.pointCount=5 fig54.typeCount=4 fig55.closed=1 fig55.filled=1 fig55.pointCount=5 fig55.typeCount=4 fig56.closed=1 fig56.filled=1 fig56.pointCount=5 fig56.typeCount=4 fig57.closed=1 fig57.filled=1 fig57.pointCount=5 fig57.typeCount=4 fig58.closed=1 fig58.filled=1 fig58.pointCount=5 fig58.typeCount=4 fig59.closed=1 fig59.filled=1 fig59.pointCount=5 fig59.typeCount=4 fig6.closed=1 fig6.filled=1 fig6.pointCount=5 fig6.typeCount=4 fig60.closed=1 fig60.filled=1 fig60.pointCount=5 fig60.typeCount=4 fig61.closed=1 fig61.filled=1 fig61.pointCount=5 fig61.typeCount=4 fig62.closed=1 fig62.filled=1 fig62.pointCount=5 fig62.typeCount=4 fig63.closed=1 fig63.filled=1 fig63.pointCount=5 fig63.typeCount=4 fig64.closed=1 fig64.filled=1 fig64.pointCount=5 fig64.typeCount=4 fig65.closed=1 fig65.filled=1 fig65.pointCount=9 fig65.typeCount=8 fig7.closed=1 fig7.filled=1 fig7.pointCount=5 fig7.typeCount=4 fig8.closed=1 fig8.filled=1 fig8.pointCount=5 fig8.typeCount=4 fig9.closed=1 fig9.filled=1 fig9.pointCount=5 fig9.typeCount=4 figCount=66 outFillRule=0 fig0.pts=[6,-1,10,-1,10,1,6,1,6,-1] fig0.start=[6,-1] fig0.types=[1,1,1,1] fig1.pts=[12,-1,16,-1,16,1,12,1,12,-1] fig1.start=[12,-1] fig1.types=[1,1,1,1] fig10.pts=[66,-1,70,-1,70,1,66,1,66,-1] fig10.start=[66,-1] fig10.types=[1,1,1,1] fig11.pts=[72,-1,76,-1,76,1,72,1,72,-1] fig11.start=[72,-1] fig11.types=[1,1,1,1] fig12.pts=[78,-1,82,-1,82,1,78,1,78,-1] fig12.start=[78,-1] fig12.types=[1,1,1,1] fig13.pts=[84,-1,88,-1,88,1,84,1,84,-1] fig13.start=[84,-1] fig13.types=[1,1,1,1] fig14.pts=[90,-1,94,-1,94,1,90,1,90,-1] fig14.start=[90,-1] fig14.types=[1,1,1,1] fig15.pts=[96,-1,100,-1,100,1,96,1,96,-1] fig15.start=[96,-1] fig15.types=[1,1,1,1] fig16.pts=[101,2,101,6,99,6,99,2,101,2] fig16.start=[101,2] fig16.types=[1,1,1,1] fig17.pts=[101,8,101,12,99,12,99,8,101,8] fig17.start=[101,8] fig17.types=[1,1,1,1] fig18.pts=[101,14,101,18,99,18,99,14,101,14] fig18.start=[101,14] fig18.types=[1,1,1,1] fig19.pts=[101,20,101,24,99,24,99,20,101,20] fig19.start=[101,20] fig19.types=[1,1,1,1] fig2.pts=[18,-1,22,-1,22,1,18,1,18,-1] fig2.start=[18,-1] fig2.types=[1,1,1,1] fig20.pts=[101,26,101,30.000001907348633,99,30.000001907348633,99,26,101,26] fig20.start=[101,26] fig20.types=[1,1,1,1] fig21.pts=[101,32,101,36,99,36,99,32,101,32] fig21.start=[101,32] fig21.types=[1,1,1,1] fig22.pts=[101,38,101,42,99,42,99,38,101,38] fig22.start=[101,38] fig22.types=[1,1,1,1] fig23.pts=[101,44,101,48,99,48,99,44,101,44] fig23.start=[101,44] fig23.types=[1,1,1,1] fig24.pts=[101,50,101,54.000003814697266,99,54.000003814697266,99,50,101,50] fig24.start=[101,50] fig24.types=[1,1,1,1] fig25.pts=[101,56,101,60.000003814697266,99,60.000003814697266,99,56,101,56] fig25.start=[101,56] fig25.types=[1,1,1,1] fig26.pts=[101,62,101,66,99,66,99,62,101,62] fig26.start=[101,62] fig26.types=[1,1,1,1] fig27.pts=[101,68,101,72,99,72,99,68,101,68] fig27.start=[101,68] fig27.types=[1,1,1,1] fig28.pts=[101,74,101,78,99,78,99,74,101,74] fig28.start=[101,74] fig28.types=[1,1,1,1] fig29.pts=[101,80,101,84,99,84,99,80,101,80] fig29.start=[101,80] fig29.types=[1,1,1,1] fig3.pts=[24,-1,28,-1,28,1,24,1,24,-1] fig3.start=[24,-1] fig3.types=[1,1,1,1] fig30.pts=[101,86,101,90,99,90,99,86,101,86] fig30.start=[101,86] fig30.types=[1,1,1,1] fig31.pts=[101,92,101,96,99,96,99,92,101,92] fig31.start=[101,92] fig31.types=[1,1,1,1] fig32.pts=[101,98,101,101,98,101,98,99,100,99,100,100,99,100,99,98,101,98] fig32.start=[101,98] fig32.types=[1,1,1,1,1,1,1,1] fig33.pts=[96,101,92,101,92,99,96,99,96,101] fig33.start=[96,101] fig33.types=[1,1,1,1] fig34.pts=[90,101,86,101,86,99,90,99,90,101] fig34.start=[90,101] fig34.types=[1,1,1,1] fig35.pts=[84,101,80,101,80,99,84,99,84,101] fig35.start=[84,101] fig35.types=[1,1,1,1] fig36.pts=[78,101,74,101,74,99,78,99,78,101] fig36.start=[78,101] fig36.types=[1,1,1,1] fig37.pts=[72,101,68,101,68,99,72,99,72,101] fig37.start=[72,101] fig37.types=[1,1,1,1] fig38.pts=[66,101,62,101,62,99,66,99,66,101] fig38.start=[66,101] fig38.types=[1,1,1,1] fig39.pts=[60,101,56,101,56,99,60,99,60,101] fig39.start=[60,101] fig39.types=[1,1,1,1] fig4.pts=[30.000001907348633,-1,34,-1,34,1,30.000001907348633,1,30.000001907348633,-1] fig4.start=[30.000001907348633,-1] fig4.types=[1,1,1,1] fig40.pts=[54,101,50,101,50,99,54,99,54,101] fig40.start=[54,101] fig40.types=[1,1,1,1] fig41.pts=[48,101,44,101,44,99,48,99,48,101] fig41.start=[48,101] fig41.types=[1,1,1,1] fig42.pts=[42,101,38,101,38,99,42,99,42,101] fig42.start=[42,101] fig42.types=[1,1,1,1] fig43.pts=[36,101,32,101,32,99,36,99,36,101] fig43.start=[36,101] fig43.types=[1,1,1,1] fig44.pts=[30,101,26,101,26,99,30,99,30,101] fig44.start=[30,101] fig44.types=[1,1,1,1] fig45.pts=[24,101,20,101,20,99,24,99,24,101] fig45.start=[24,101] fig45.types=[1,1,1,1] fig46.pts=[18,101,14,101,14,99,18,99,18,101] fig46.start=[18,101] fig46.types=[1,1,1,1] fig47.pts=[12,101,8,101,8,99,12,99,12,101] fig47.start=[12,101] fig47.types=[1,1,1,1] fig48.pts=[6,101,2,101,2,99,6,99,6,101] fig48.start=[6,101] fig48.types=[1,1,1,1] fig49.pts=[-1,100,-1,96,1,96,1,100,-1,100] fig49.start=[-1,100] fig49.types=[1,1,1,1] fig5.pts=[36,-1,40,-1,40,1,36,1,36,-1] fig5.start=[36,-1] fig5.types=[1,1,1,1] fig50.pts=[-1,94,-1,90,1,90,1,94,-1,94] fig50.start=[-1,94] fig50.types=[1,1,1,1] fig51.pts=[-1,88,-1,84,1,84,1,88,-1,88] fig51.start=[-1,88] fig51.types=[1,1,1,1] fig52.pts=[-1,82,-1,78,1,78,1,82,-1,82] fig52.start=[-1,82] fig52.types=[1,1,1,1] fig53.pts=[-1,76,-1,72,1,72,1,76,-1,76] fig53.start=[-1,76] fig53.types=[1,1,1,1] fig54.pts=[-1,70,-1,66,1,66,1,70,-1,70] fig54.start=[-1,70] fig54.types=[1,1,1,1] fig55.pts=[-1,64,-1,60,1,60,1,64,-1,64] fig55.start=[-1,64] fig55.types=[1,1,1,1] fig56.pts=[-1,58,-1,54,1,54,1,58,-1,58] fig56.start=[-1,58] fig56.types=[1,1,1,1] fig57.pts=[-1,52,-1,48,1,48,1,52,-1,52] fig57.start=[-1,52] fig57.types=[1,1,1,1] fig58.pts=[-1,45.999996185302734,-1,42,1,42,1,45.999996185302734,-1,45.999996185302734] fig58.start=[-1,45.999996185302734] fig58.types=[1,1,1,1] fig59.pts=[-1,39.999996185302734,-1,36,1,36,1,39.999996185302734,-1,39.999996185302734] fig59.start=[-1,39.999996185302734] fig59.types=[1,1,1,1] fig6.pts=[42,-1,46,-1,46,1,42,1,42,-1] fig6.start=[42,-1] fig6.types=[1,1,1,1] fig60.pts=[-1,34,-1,30,1,30,1,34,-1,34] fig60.start=[-1,34] fig60.types=[1,1,1,1] fig61.pts=[-1,28,-1,24,1,24,1,28,-1,28] fig61.start=[-1,28] fig61.types=[1,1,1,1] fig62.pts=[-1,22,-1,18,1,18,1,22,-1,22] fig62.start=[-1,22] fig62.types=[1,1,1,1] fig63.pts=[-1,16,-1,12,1,12,1,16,-1,16] fig63.start=[-1,16] fig63.types=[1,1,1,1] fig64.pts=[-1,10,-1,6,1,6,1,10,-1,10] fig64.start=[-1,10] fig64.types=[1,1,1,1] fig65.pts=[-1,4,-1,-1,4,-1,4,1,0,1,0,0,1,0,1,4,-1,4] fig65.start=[-1,4] fig65.types=[1,1,1,1,1,1,1,1] fig7.pts=[48,-1,52,-1,52,1,48,1,48,-1] fig7.start=[48,-1] fig7.types=[1,1,1,1] fig8.pts=[54.000003814697266,-1,58,-1,58,1,54.000003814697266,1,54.000003814697266,-1] fig8.start=[54.000003814697266,-1] fig8.types=[1,1,1,1] fig9.pts=[60.000003814697266,-1,64,-1,64,1,60.000003814697266,1,60.000003814697266,-1] fig9.start=[60.000003814697266,-1] fig9.types=[1,1,1,1]`

### `widen_rect_tol_0_001` — Structural

- 意图：圆 + 描边：容差是否影响输出点数？
- 结论：输出键集合不同：win 缺 [fig1.filled,fig1.closed,fig1.pointCount,fig1.typeCount,fig1.start,fig1.pts,fig1.types] 
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=1267 fig0.typeCount=1266 figCount=1 outFillRule=1592590337 fig0.pts=[89,50,91,50,90.99916076660156,50.2650260925293,90.99665069580078,50.529659271240234,90.99246215820312,50.79390335083008,90.98661804199219,51.05774688720703,90.9791030883789,51.32118225097656,90.96994018554688,51.58421325683594,90.9591293334961,51.846824645996094,90.94667053222656,52.1090202331543,90.93257141113281,52.37078857421875,90.91683959960938,52.63212585449219,…] fig0.start=[89,50] fig0.types=[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,…]`
- Linux　：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=25 fig0.typeCount=8 fig1.closed=1 fig1.filled=1 fig1.pointCount=25 fig1.typeCount=8 figCount=2 outFillRule=0 fig0.pts=[91,50,91,61.32181930541992,86.99712371826172,70.98561096191406,78.99137878417969,78.99137878417969,70.98564910888672,86.99712371826172,61.321861267089844,91,50,91,38.67818069458008,91,29.014389038085938,86.99712371826172,21.008621215820312,78.99137878417969,13.002873420715332,70.98564910888672,9.000000953674316,61.321861267089844,…] fig0.start=[91,50] fig0.types=[2,2,2,2,2,2,2,2] fig1.pts=[89,50,89,39.230445861816406,85.19239044189453,30.038061141967773,77.57716369628906,22.422836303710938,69.96195983886719,14.807611465454102,60.76957321166992,11.000000953674316,50,11.000003814697266,39.230445861816406,11.000021934509277,30.038061141967773,14.807632446289062,22.422836303710938,22.422836303710938,14.807611465454102,30.038040161132812,11.000000953674316,39.23042678833008,…] fig1.start=[89,50] fig1.types=[2,2,2,2,2,2,2,2]`

### `widen_rect_tol_10` — Structural

- 意图：圆 + 描边、大容差
- 结论：输出键集合不同：win 缺 [fig1.filled,fig1.closed,fig1.pointCount,fig1.typeCount,fig1.start,fig1.pts,fig1.types] 
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=19 fig0.typeCount=18 figCount=1 outFillRule=1592590337 fig0.pts=[89,50,91,50,78.99137878417969,78.99137878417969,50,91,21.008621215820312,78.99137878417969,9,50,21.008621215820312,21.008621215820312,50,9,78.99137878417969,21.008621215820312,91,50,89,50,77.57716369628906,22.422834396362305,…] fig0.start=[89,50] fig0.types=[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]`
- Linux　：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=25 fig0.typeCount=8 fig1.closed=1 fig1.filled=1 fig1.pointCount=25 fig1.typeCount=8 figCount=2 outFillRule=0 fig0.pts=[91,50,91,61.32181930541992,86.99712371826172,70.98561096191406,78.99137878417969,78.99137878417969,70.98564910888672,86.99712371826172,61.321861267089844,91,50,91,38.67818069458008,91,29.014389038085938,86.99712371826172,21.008621215820312,78.99137878417969,13.002873420715332,70.98564910888672,9.000000953674316,61.321861267089844,…] fig0.start=[91,50] fig0.types=[2,2,2,2,2,2,2,2] fig1.pts=[89,50,89,39.230445861816406,85.19239044189453,30.038061141967773,77.57716369628906,22.422836303710938,69.96195983886719,14.807611465454102,60.76957321166992,11.000000953674316,50,11.000003814697266,39.230445861816406,11.000021934509277,30.038061141967773,14.807632446289062,22.422836303710938,22.422836303710938,14.807611465454102,30.038040161132812,11.000000953674316,39.23042678833008,…] fig1.start=[89,50] fig1.types=[2,2,2,2,2,2,2,2]`

### `widen_negative_thickness` — Structural

- 意图：负笔宽
- 结论：输出键集合不同：win 缺 [fig1.filled,fig1.closed,fig1.pointCount,fig1.typeCount,fig1.start,fig1.pts,fig1.types] 
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=24 fig0.typeCount=23 figCount=1 outFillRule=1592590337 fig0.pts=[0,1,0,-1,100,-1,101,-1,101,100,101,101,0,101,-1,101,-1,0,-1,-1,0,-1,1,0,…] fig0.start=[0,1] fig0.types=[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]`
- Linux　：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=5 fig0.typeCount=4 fig1.closed=1 fig1.filled=1 fig1.pointCount=5 fig1.typeCount=4 figCount=2 outFillRule=0 fig0.pts=[-1,-1,101,-1,101,101,-1,101,-1,-1] fig0.start=[-1,-1] fig0.types=[1,1,1,1] fig1.pts=[1,1,1,99,99,99,99,1,1,1] fig1.start=[1,1] fig1.types=[1,1,1,1]`

### `widen_with_matrix` — Structural

- 意图：矩阵只作用于几何、不作用于笔（geometry_api.cpp:154）
- 结论：输出键集合不同：win 缺 [fig1.filled,fig1.closed,fig1.pointCount,fig1.typeCount,fig1.start,fig1.pts,fig1.types] 
- Windows：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=227 fig0.typeCount=226 figCount=1 outFillRule=1592590337 fig0.pts=[179,100,181,100,180.89462280273438,104.16741180419922,180.58184814453125,108.28057098388672,180.06674194335938,112.33425903320312,179.35438537597656,116.3232650756836,178.44984436035156,120.24242401123047,177.3582305908203,124.08655548095703,176.08465576171875,127.85050964355469,174.6342010498047,131.52915954589844,173.0120086669922,135.11740112304688,171.22314453125,138.61009216308594,…] fig0.start=[179,100] fig0.types=[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,…]`
- Linux　：`hr=0x00000000 fig0.closed=1 fig0.filled=1 fig0.pointCount=25 fig0.typeCount=8 fig1.closed=1 fig1.filled=1 fig1.pointCount=25 fig1.typeCount=8 figCount=2 outFillRule=0 fig0.pts=[181,100,181,122.36767578125,173.09188842773438,141.45956420898438,157.27565002441406,157.27565002441406,141.4593963623047,173.09188842773438,122.36751556396484,181,100,181,77.63248443603516,181,58.54060363769531,173.09188842773438,42.72434997558594,157.27565002441406,26.9081974029541,141.4593963623047,19.000083923339844,122.36751556396484,…] fig0.start=[181,100] fig0.types=[2,2,2,2,2,2,2,2] fig1.pts=[179,100,179,78.18473052978516,171.28713989257812,59.56425476074219,155.86143493652344,44.13856506347656,140.43557739257812,28.712854385375977,121.81510925292969,21.000001907348633,100,21.00000762939453,78.18473052978516,21.000001907348633,59.56425476074219,28.712854385375977,44.13856506347656,44.13856506347656,28.712854385375977,59.56425476074219,21.000001907348633,78.18473052978516,…] fig1.start=[179,100] fig1.types=[2,2,2,2,2,2,2,2]`

### `tb_zero_width_viewport` — Deviation

- 意图：★ viewport 宽 0：上游 IsRectEmptyOrInvalid 不判 0 面积 → 除零。我方刻意加固
- 结论：首个数值差异：brushIsEmpty: win=0 lin=1 (Δabs=1 Δrel=1)（共 3 处）
- Windows：`hr=0x00000000 brushIsEmpty=0 vb.h=50 vb.w=50 vb.x=0 vb.y=0 vp.h=100 vp.w=0 vp.x=0 vp.y=0 contentToShape=[0,0,0,0,0,2,0,0,0,0,1,0,0,0,0,1]`
- Linux　：`hr=0x00000000 brushIsEmpty=1 vb.h=50 vb.w=50 vb.x=0 vb.y=0 vp.h=100 vp.w=0 vp.x=0 vp.y=0 contentToShape=[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1]`
- 差异明细：
  - `brushIsEmpty: win=0 lin=1 (Δabs=1 Δrel=1)`
  - `contentToShape[0]: win=0 lin=1 (Δabs=1 Δrel=1)`
  - `contentToShape[5]: win=2 lin=1 (Δabs=1 Δrel=0.5)`

### `tb_zero_height_viewport` — Deviation

- 意图：★ viewport 高 0
- 结论：首个数值差异：brushIsEmpty: win=0 lin=1 (Δabs=1 Δrel=1)（共 3 处）
- Windows：`hr=0x00000000 brushIsEmpty=0 vb.h=50 vb.w=50 vb.x=0 vb.y=0 vp.h=0 vp.w=100 vp.x=0 vp.y=0 contentToShape=[2,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1]`
- Linux　：`hr=0x00000000 brushIsEmpty=1 vb.h=50 vb.w=50 vb.x=0 vb.y=0 vp.h=0 vp.w=100 vp.x=0 vp.y=0 contentToShape=[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1]`
- 差异明细：
  - `brushIsEmpty: win=0 lin=1 (Δabs=1 Δrel=1)`
  - `contentToShape[0]: win=2 lin=1 (Δabs=1 Δrel=0.5)`
  - `contentToShape[5]: win=0 lin=1 (Δabs=1 Δrel=1)`

### `tb_zero_width_viewbox` — Deviation

- 意图：★ viewbox 宽 0：上游 scaleX = 100/0 = +INF
- 结论：首个数值差异：brushIsEmpty: win=0 lin=1 (Δabs=1 Δrel=1)（共 1 处）
- Windows：`hr=0x00000000 brushIsEmpty=0 vb.h=50 vb.w=0 vb.x=0 vb.y=0 vp.h=100 vp.w=100 vp.x=0 vp.y=0 contentToShape=[NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN]`
- Linux　：`hr=0x00000000 brushIsEmpty=1 vb.h=50 vb.w=0 vb.x=0 vb.y=0 vp.h=100 vp.w=100 vp.x=0 vp.y=0 contentToShape=[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1]`
- 差异明细：
  - `brushIsEmpty: win=0 lin=1 (Δabs=1 Δrel=1)`

### `tb_zero_height_viewbox` — Deviation

- 意图：★ viewbox 高 0
- 结论：首个数值差异：brushIsEmpty: win=0 lin=1 (Δabs=1 Δrel=1)（共 1 处）
- Windows：`hr=0x00000000 brushIsEmpty=0 vb.h=0 vb.w=50 vb.x=0 vb.y=0 vp.h=100 vp.w=100 vp.x=0 vp.y=0 contentToShape=[NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN]`
- Linux　：`hr=0x00000000 brushIsEmpty=1 vb.h=0 vb.w=50 vb.x=0 vb.y=0 vp.h=100 vp.w=100 vp.x=0 vp.y=0 contentToShape=[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1]`
- 差异明细：
  - `brushIsEmpty: win=0 lin=1 (Δabs=1 Δrel=1)`

### `tb_zero_shape_bounds` — Deviation

- 意图：填充包围盒 0 面积时的相对单位展开
- 结论：首个数值差异：brushIsEmpty: win=0 lin=1 (Δabs=1 Δrel=1)（共 3 处）
- Windows：`hr=0x00000000 brushIsEmpty=0 vb.h=50 vb.w=50 vb.x=0 vb.y=0 vp.h=0 vp.w=0 vp.x=0 vp.y=0 contentToShape=[0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1]`
- Linux　：`hr=0x00000000 brushIsEmpty=1 vb.h=50 vb.w=50 vb.x=0 vb.y=0 vp.h=0 vp.w=0 vp.x=0 vp.y=0 contentToShape=[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1]`
- 差异明细：
  - `brushIsEmpty: win=0 lin=1 (Δabs=1 Δrel=1)`
  - `contentToShape[0]: win=0 lin=1 (Δabs=1 Δrel=1)`
  - `contentToShape[5]: win=0 lin=1 (Δabs=1 Δrel=1)`

### `length_line_nan` — Structural

- 意图：NaN 分数
- 结论：HRESULT 不同：win=0x00000000 lin=0x80004005
- Windows：`hr=0x00000000 point=[NaN,NaN] tangent=[1,0]`
- Linux　：`hr=0x80004005 point=[0,0] tangent=[0,0]`

### `length_circle_0_3` — Deviation

- 意图：曲线上的点与切线
- 结论：首个数值差异：point[0]: win=-3.09100604057312 lin=-3.1091458797454834 (Δabs=0.0181 Δrel=0.00583)（共 4 处）
- Windows：`hr=0x00000000 point=[-3.09100604057312,9.513132095336914] tangent=[-0.9511194825172424,-0.3088228702545166]`
- Linux　：`hr=0x00000000 point=[-3.1091458797454834,9.507223129272461] tangent=[-0.9505239725112915,-0.3106512725353241]`
- 差异明细：
  - `point[0]: win=-3.09100604057312 lin=-3.1091458797454834 (Δabs=0.0181 Δrel=0.00583)`
  - `point[1]: win=9.513132095336914 lin=9.507223129272461 (Δabs=0.00591 Δrel=0.000621)`
  - `tangent[0]: win=-0.9511194825172424 lin=-0.9505239725112915 (Δabs=0.000596 Δrel=0.000626)`
  - `tangent[1]: win=-0.3088228702545166 lin=-0.3106512725353241 (Δabs=0.00183 Δrel=0.00589)`


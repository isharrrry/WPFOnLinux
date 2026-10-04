# 全块矩阵回归（#8 件上，11 块）— 2026-09-14（T3）

**件** = `#8`（`ACCEPTANCE-BASELINE.md`）：`bridge 759a322431f1e457` ｜ `pc 6be29475b6aeb34e` ｜ `pf 50da85138a7bc3e8` ｜
`wb e6216fe961a2bfb9` ｜ `win32shim 91baee84270f2322` ｜ `hbtextline e1bc947afc248b32` ｜ `dwf 2f77dbdf5e7e2cd5`。
**目的**：给"剩余在册项"一张应用侧证据面，并**端到端验证"块表 vs 样例注册表"**（L19 的收口）。

## 0｜机器强制的注册表断言（本轮新增）

- **判据（直接测量）**：注册表由 `tests/…/probe-block-registry.py` **从样例源码**取出
  （`MainWindow.xaml.cs` 的 `all` 列表 → 经 `FeatureBlocks.cs` 映射出块名），与 runner 的 `BLOCKS` 比
  **集合 + 条目数**；不一致 ⇒ 打印 `MISMATCH` 并**点名缺哪个/多哪个**，**并把本趟判红**（`REGISTRY_RC=1` 并进门禁结论）。
- **为什么不是恒真**：`WFP_BLOCK_REGISTRY_SELFTEST=1` 三极性实测（**不跑应用**）：
```
WFP_BLOCK_REGISTRY_SELFTEST 真表=ok(count=11，与样例注册表逐名一致)
WFP_BLOCK_REGISTRY_SELFTEST 删一块=MISMATCH(块表缺=text-dp-min)      ← 能红，且**点名**
WFP_BLOCK_REGISTRY_SELFTEST 加假块=MISMATCH(块表多=__bogus_block__)   ← 能红，且点名
WFP_BLOCK_REGISTRY_SELFTEST=PASS（能绿：真表；能红且点名：缺块/多块）
```
- **端到端**：应用自报的构建块数也要与"期望块数"相等（全量=表长；`--only`=被选个数），
  不符或取不到 ⇒ **判红**（不许"无信息"过关）。实测：`✅ 应用自报构建块数=11 == 期望(11)`；三块趟 `=3 == 期望(3)`。
- ⚠️ **实现教训（我第一版放错位置）**：断言最初放在 **4/5 汇总段** ⇒ 自测牙**先白跑了一趟应用**才退出。
  现已把"块表 + 断言 + 牙"整段移到 **3/5 起应用之前**（断言失败要能早退）。

## 1｜全量趟（`only=all`）：逐块判定与关键读数

`WFP_BLOCK_REGISTRY=ok(count=11，与样例注册表逐名一致)` ｜ `WFP_SUMMARY blocks=11 ok=8 fail=3 inconclusive=0 skipped=0`
｜ `WFP_GATE=FAIL blocks=11 ok=8 fail=3`（**这 3 个 FAIL 经下面第 2 节证伪为"采样范围"伪影，不是缺陷**）
｜ 帧 `14/14`、`blank=0`、`colors=1309`、`new_windows=9`、`leftover_after=0`、skia 指令 **433 条 / 未画种类 0**。

| 块 | 判定 | 关键读数（逐字） |
|---|---|---|
| popup | **OK** | `popup.IsOpen=True child=120x28 menu.IsOpen=False menu.items=2 tip.IsOpen=True`；像素 `#E5484D=29316` |
| anim | **OK** | `opacity 0.00→1.00(100%) xform 0.0→40.0(100%) width 40.0→120.0(100%)`；`#F5A524=36848` |
| opacitymask | **OK** | 负向 `#8B5CF6=0<20`（不可见）/ 正向 `#22C55E=28644` |
| effects | **OK** | DropShadow `#0EA5E9=23184` / Blur `#EC4899=22176` |
| controls | **OK** | `tabs=3(容器已生成=True) tree=3 grid.cols=2 grid.rows=12`；`#14B8A6=152222` |
| textbox-edit | **FAIL→伪影** | 全量趟 `FAIL(#F97316=0)` 在框 `240x24+21+683` 内；**整帧实读该色 288 px（18/18 帧都有）** ⇒ 色在，**不在那个框里** |
| virtualize | **OK** | `late: items=200 已实现容器=8`；`#64748B=1344` |
| transforms | **FAIL→伪影** | 全量趟 `#EAB308=2282` 但 `#94A3B8=0`；该卡在**视口之下**（见 §2） |
| text-rtl | **FAIL→伪影** | 全量趟 `#A855F7=0`；同上，**18/18 帧里 0 px** |
| text-rtl-pure | **OK** | `#FF2D95=26110 #00FF7F=30254 #00E5FF=176302 #ADFF2F=3276 #C084FC=44128`（`:norect` 整帧）＋ census `GlyphRun×86` |
| text-dp-min | **OK** | `WFP_TEXTDP t4='A' c4=1 sel='A' line0='A'`（零注入；`blocks=11 ok=1 skipped=10` 那次逐字相同） |

## 2｜3 个 FAIL 的归属：**采样范围伪影，不是缺陷**（已证伪）

**证据链（全部本趟实读，可复算）**：
1. **三块的应用自报都是 `OK`**（`[feat] textbox-edit OK` / `transforms OK` / `text-rtl OK`）；
2. **布局坐标远超视口**：窗口 `938x938`，而 `WFP_BOXID` 报 `text-rtl-pure` 系在 **y=1192…1273**；
   且本趟有 `WM_MOUSEWHEEL=6`（runner 会滚动）⇒ **布局坐标 ≠ 截屏时的屏幕坐标**；
3. **整帧穷举**（18 张 png 逐张直方图）：
```
#A855F7 (text-rtl)        总=0     非零帧=0/18
#94A3B8 (transforms/Clip) 总=0     非零帧=0/18
#F97316 (textbox-edit)    总=288   非零帧=18/18（每帧 16 px）
```
   ⇒ 前两块的颜色**根本没进过任何一帧**（卡片在视口之下、滚动没到）；textbox-edit 的色**一直在**、只是不在框里。
4. **反证（把三块放到最上面重跑 `--only=textbox-edit,transforms,text-rtl`）**：
```
transforms    OK   OK(#EAB308=37842 #94A3B8=38080)
text-rtl      OK   OK(#A855F7=4942)
textbox-edit  INCONCLUSIVE  OK(#F97316=1582)（限框 240x24+21+39 内计数）＋ census GlyphRun×25≥1
WFP_SUMMARY blocks=11 ok=2 fail=0 inconclusive=1 skipped=8 ｜ WFP_GATE=INCONCLUSIVE（textbox-edit 按 D-P1 既定口径记 INCONCLUSIVE）
```
⇒ **同一件、同一判据，块可见时全绿** ⇒ 全量趟那 3 个 FAIL 是**视口/滚动导致的采样范围问题**。
**（textbox-edit 的 INCONCLUSIVE 不是像素问题：像素腿 `OK(#F97316=1582)`；INCONCLUSIVE 来自既定的"写后读数/输入腿"口径。）**

**结论（写进在册）**：`--only`（少块、内容短、不需要滚动）是**深部块**的正确仪器；全量趟的像素腿
**只对"确实出现在视口内"的块有效**。⇒ 建议：全量趟的像素 FAIL 一律先过一遍"该色在 18 帧里出现过吗"再定性（我已把它写成上面的可复算步骤）。

## 3｜"剩余在册项"在本应用侧覆盖到哪：**三条都不测**（"不测"也是结论）

| 在册项 | 应用侧（WpfFeatureProbe） | 覆盖在哪 |
|---|---|---|
| **Tab 口径** | **本应用不测这条**：样例文本里**没有 `\t` 字面量**（grep 无命中） | `tline`：`Tab 可比例 34 例，其中不一致 0 例` = **已登记差异·保留红**（真机 = 0 宽 + 特定断点，本实现未做） |
| **Collapse 明细** | **本应用不测这条**：应用侧计数器全 0（`Collapse=0 collapseCalls=0 collapsedRangesNull=0`，取自本车道落盘的应用 dump）⇒ **那条路在应用里根本没走到** | `tline`：`折叠判定一致 1298/1298`；真折叠 236 行，**明细全等 218/236**（差 **18 条** = T1c 正在做的那批） |
| **Extent** | **本应用不测这条**：应用侧无 Extent 读数（HB 侧给的是 `h/bl/w`） | `tline`：`Extent 1260/1298`，余差 **58 条**（主对拍 38 + LH 组 20，容差 0.01 DIP） |
| （附）折行/省略号 | **本应用测**：`text-rtl` 块报 `wrap.wrap=Wrap wrap.h=45.4`、`trim.trimming=CharacterEllipsis trim.h=45.4` | 应用侧自报 + 像素（`#A855F7=4942`）；明细对拍仍在 `tline` |

## 4｜run 目录索引
`~/wfp-runs/go-matrix8`（全量 11 块）｜`~/wfp-runs/go-matrix8-3blk`（三块反证）｜`~/.wfp-runs` 之外无落盘。
`samples/WpfTextDemo/WAVE21-FINAL-ROUND.md`（#8 最终轮：门禁/tline/RTL/DP 反证/写后读数）为配套证据。

> ⚠️ **时序提示（主控口径）**：本任务产出放在**波前**（#8 收官证据）。跑本矩阵时 `WFP_SRC_STALE` 已列出
> 7 个工程的**源比产物新**（T1b/T1c/T1d/U1/T2/M7b 并行在改）⇒ 这些读数描述的是 **#8 的产物**，
> **不代表当前树**；新波重建后需按主控清单在新件上重取。

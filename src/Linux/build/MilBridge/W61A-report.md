# W61A 报告 —— `D-G57`（页签标题 / 「实用例子」按钮 / 搜索框 Placeholder **文字零墨**）：**(a)/(b) 分野已定，二者皆非；真判定点 = 单段行用错面画字形**

> 车道 **W61A**｜2026-09-20 23:41 → 2026-09-21 00:2x +0800｜kernel `6.8.0-138-generic`｜`nproc=3`
> 仓根 `$R = /home/links-dev/netTest/wpf-linux-20260906/wpf-linux`
> 写域使用情况：**仓内只新建本报告**；`build/shims/PresentationCore.HbTextLine.cs` 曾按修法改动并重建 `pc`，**已按主控排程裁定逐字节复原**（§2.3 有 `cmp` 证据）；`$HOME/w61a/**` 全是仓外私有件。
> 报告自身 sha16 = `81b920d6755516bb`（口径：删掉**本行**后的整份文件 `sha256sum | cut -c1-16`）

---

## 结论在前（TL;DR）

1. **`D-G57` 的 (a)/(b) 二选一，两个都不是**：
   * **(b)（子树绘制指令未进通道）被推翻**：选中页签的 **2 px 下划线真在屏上** —— `y=345` 与 `y=346` 各 **116 px `#326CF3`**（= hc `TitleColor`），同排 `y=347` 还有 TabControl 的 `#E0E0E0` 上边框（270 px）。**W52A 的"整块零绘制 / 下划线也没落屏"是裁剪矩形差 1 px 造成的假读数**（他们的 `228x27+318+318` 只盖到 `y=344`）。
   * **(a)（画刷解析成白/透明）被推翻**：进程内逐行读数（`HBLINE D#…brush=`）显示三处文字的画刷**都非空、且颜色正确**：页签 `#FF212121`（未选中）/ `LinearGradientBrush`（选中态 = `PrimaryBrush`）、按钮 `#FF212121`、Placeholder `#FFBDBDBD`。
2. **真判定点（代码级）= `build/shims/PresentationCore.HbTextLine.cs:2823-2826`**：
   单段分支 `_glyphRun = BuildGlyphRun(shaped, glyphTypeface, …)` **恒用"段落主面"（= DejaVu Sans）**，而 `shaped` 里的字形 id 是 `ShapeParagraph`（`:650`：`HbShaper.Shape(seg.Face.Path, …)`）**按计划里的段面（= NotoSansCJK-Regular.ttc）整形出来的**⇒ **用 A 面的 id 去 B 面取字形** ⇒ 越界/`.notdef` ⇒ **零墨、零异常**。
3. **一条判据把整族现象一次解释干净**：**"整行只落成一段回退面"的行全灭，"多段"的行全活**。
   * 活：**31 个导航项**（`ZWSP + CJK + ZWSP` = 3 段）→ `HBLINE D#… [r1 face=NotoSansCJK-Regular.ttc glyphs=2 chars="画刷"]`（走 `:2838-2841` 的多段分支，面取对）。
   * 灭：**12 条单段绘制记录（9 个文案）** —— 3 个页签标题「样式模板/控件/工具」、按钮「实用例子」、Placeholder「请输入关键字」，以及导航尾部 **4** 项（代码仓库/关于/群友推荐/敬请期待）→ `HBLINE D#… [r0 face=DejaVuSans.ttf glyphs=4 chars="样式模板"]`（走 `:2826` 单段分支，面取错）。
   * 旁证：同一趟里 `[TEXTLINE_DIAG] R1 面计划 … ⇒ segments=1 0:[0,4) /usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc#0 (按码点回退) slot=1` —— **计划是对的，画的时候面丢了**。
4. **修法已写成 `proposed-fix.diff`（未落地）**：`$HOME/w61a/diff/W61A-D-G57-shim-singleface.diff`（42 行，sha16 `cac51d6f54ad9845`）。落地态曾实测：shim `e89fed55fd8e32bc` → `921ba9c65e9fb3be`、`pc` `9465f9dce39e2dfc` → `21e3e88a5090cd3b`（0 警 0 错，28.7 s），**随后逐字节复原**（§2.3）。
5. **两极化只取到负极**：负极 = 现树实测 `页签行 colors=1 / stddev=0.00%`、`按钮 8 / 0.15%`、`搜索框 19 / 2.71%`、导航项 `69 / 10.47%`（与 W47A/W52A **逐位相同**）；**正极（修后）与零回归腿按主控排程裁定未跑**，配方与期望读数见 §3.2。

---

## §0 环境与装置

| 项 | 读数 |
|---|---|
| 车道 / 时间 | `W61A`｜2026-09-20 23:41:00 → 2026-09-21 00:2x +0800 |
| kernel / `nproc` | `6.8.0-138-generic` / 3 |
| 显示 | **`:198`**（自建 `Xvfb :198 -screen 0 1400x1050x24`；派单书建议的 `:196` 与 `:197` 开跑时**已被别的车道占用**（`Xvfb :196 1024x768`、`Xvfb :197 1280x1024`）⇒ 用 :198）。**未碰** `:0/:1/:10/:97/:99/:151/:152/:168/:169/:171/:172/:191/:192/:195` |
| 窗口 | `xwininfo`：`Absolute upper-left X: 300  Y: 225  Width: 800  Height: 600  Map State: IsViewable` —— 与 W52A/W47A 同几何 ⇒ 四区矩形可直接沿用 |
| `MemAvailable` | 开工 **2,390 MB**（23:58）／最低 **2,053 MB**（00:05）／收工 **2,503 MB**（00:15 构建前） |
| `loadavg` | 开工 `1.30 1.45 1.47`／峰值 `2.57`／收工 `1.6` 一档 |
| 机级重活槽 | **所有起应用/构建的整条命令都包进 `~/heavy-slot.sh`**（主控 2026-09-21 裁定）：`SLOT HEAVYSLOT=ACQUIRED waited=264s`（diag1）／`waited=40s`（diag2）／`waited=180s`（PC 重建）。未出现 `rc=137`、未出现槽超时 |
| 私有应用目录 | `$HOME/w61a/app`（`cp -a` 自 `/home/links-dev/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0`，23:56 快照；两趟读数**件未动**） |

### 五件 sha16（**两趟读数完全相同**；本报告只对这套件负责）

| 件 | `$HOME/w61a/app`（diag1 = diag2） |
|---|---|
| `libwpfwin32.so` | `054037aadfd7d192`（304,016 B） |
| `wpfgfx_cor3.so`（桥） | **`e3ea092010734f44`**（5,019,968 B） |
| `PresentationCore.dll`（pc） | `9465f9dce39e2dfc`（3,601,408 B） |
| `PresentationFramework.dll`（pf） | `1011da6390c3bf1e`（6,119,424 B） |
| `WindowsBase.dll`（wb） | `2e4e46e539a72cd7`（1,111,552 B） |
| 五件合并指纹 | `FIVE_FP=95a98b711bfe7ea5` |

⚠️ **件是"跑起来的那一套"，不是"仓内权威那一套"**（如实记）：本趟仓内权威 `bridge=79e45aed26487045`（**W62A 在 23:52 重发过桥**）、`win32shim=09466f9c12f5b606`（W59A 正在改原生 shim）⇒ 树**处于波中**。本车道**没有**用 `sync-applocal.sh` 拉权威件，理由见 §2.3：两极化要求"只差被测那一件"，而拉权威会把**桥**也换掉（同一趟里换两件 ⇒ 归因不成立）。

### 仓内九位（我的改动复原后现场复算，供主控对账）

`bridge=79e45aed26487045`｜**`pc=9465f9dce39e2dfc`**｜`pf=1011da6390c3bf1e`｜`windowsbase=2e4e46e539a72cd7`｜**`hbtextline=e89fed55fd8e32bc`（290,825 B）**｜`win32shim=09466f9c12f5b606`｜`wic_shim=56278c14b4ecd672`｜`provider=1f9511a7ef395bfe`｜`dwf=de2d555105b7d04b`
（`hbtextline` 与 `pc` 是我这趟唯一碰过的两位，**都已复原到开工值**；`bridge`/`win32shim` 的位移**不是我的**。）

---

## §1 第 1 步：只读探针 —— (a)/(b) 的裁决

### 1.1 仪器（**零重建**，全部是仓内既有的、缺省关的只读仪表）

| 仪表 | 开关 | 本趟用途 |
|---|---|---|
| `DrawInstructionCensus`（桥） | `WPF_LINUX_DRAW_CENSUS=1` | 每帧指令种类/次数 + 逐条几何的**设备包围盒 + 画刷颜色** |
| `GlyphRunCensus`（桥） | `WPF_LINUX_GLYPH_CENSUS=1` | 逐字形 run 的 origin/设备坐标/字形 id |
| `GlyphFaceCensus`（桥） | `WPF_LINUX_GLYPH_FACE_CENSUS=1` | 用了哪些面、面来源（句柄/族名） |
| `WpfLinuxLineHeightTrace`（PC `SimpleTextLine`） | `WPF_LINUX_LINEHEIGHT_TRACE=1` | **快路径**的 `Draw` origin + run 数 |
| `HbLineTrace`（shim，站点 A/B/C/D/E） | `WPF_LINUX_HBLINE_TRACE=1` | **逐行**：Draw 收到几次调用、宿主 origin、**真正交给 `DrawGlyphRun` 的每张 glyph run 的"面 + 字形数 + 字符"**、**每张 run 拿到的前景画刷** |
| `HbTextLineScaffold` 逐行 dump | `WPF_LINUX_TEXTLINE_PERLINE=1` + `WPF_LINUX_TEXTLINE_DUMP=<file>` | 每一条被 shim 构造的行：`len/nl/runs=字形run数/**text=前16字符**` |
| `HbFallbackDiag` | `WPF_LINUX_TEXTLINE_DIAG=1` | R1 **面计划**逐段（含"按码点回退"与 `slot=`） |
| `WpfLinuxDpValueTrace`（WB） | `WPF_LINUX_INPUT_TRACE=1` | `Text` DP 的读/写路径（本趟只作旁证） |

复算命令见 §5。

### 1.2 读数 ①：**页签子树是有绘制的**（推翻 (b) 的原文表述）

同一趟 `root.png`（sha16 `9380291b84d81dd6`）逐行扫描 `x∈[300,570]`：

```
y=345 x=[300..569] n=116  sample=#326CF3
y=346 x=[300..569] n=116  sample=#326CF3
y=347 x=[300..569] n=270  sample=#E0E0E0      ← TabControl 的 1px 上边框（BorderColor）
```

* `#326CF3` = hc `Themes/Basic/Colors/Colors.xaml:37 TitleColor` ⇒ 这 2 行就是 **`TabItemStyle` 模板里 `mainBorder` 的 `BorderThickness=0,0,0,2` 选中下划线**（`TabControlBaseStyle.xaml` 的 `MultiDataTrigger` 生效了）。
* 逐行墨量复算（`analyze.py rows`）：`y=318..344`（W52A 的 27 行裁剪区）**确实全 0**，但 `y=345/346` 有墨 ⇒ **他们的结论是裁剪矩形少 1~2 px 的产物**，不是我方渲染缺失。
* 区域读数（同脚本同阈值）：`页签行 228x27+318+318 → colors=1 stddev=0.00%`；而 `下划线带 228x4+318+343 → colors=2 stddev=22.00%、非众数像素=156`。

**⇒ (b)「该子树的绘制指令根本没进通道」不成立**：`mainBorder`（Border，`hc:SimplePanel` 的第 1 个子件）的画在。

### 1.3 读数 ②：三处零墨的**字符串非空、且已被 shim 排版**（推翻"空串"与"没排版"）

`hbline.log`（shim 逐行 dump，278 行 / 83 条行记录）里的**逐字命中**：

```
HBLINE_LINE#11 … len=5 nl=1 visible=4 runs=1 text="样式模板"      ← 页签#1（Styles，选中态）
HBLINE_LINE#44 … len=5 nl=1 visible=4 runs=1 text="样式模板"      ← 同上（渲染相位再来一次）
HBLINE_LINE#82 … len=3 nl=1 visible=2 runs=1 text="控件"          ← 页签#2（Controls）
HBLINE_LINE#83 … len=3 nl=1 visible=2 runs=1 text="工具"          ← 页签#3（Tools）
HBLINE_LINE#12 … len=7 nl=1 visible=6 runs=1 text="请输入关键字"   ← SearchBar Placeholder
HBLINE_LINE#5  … len=5 nl=1 visible=4 runs=1 text="实用例子"      ← 「实用示例」按钮（**注意：lang 真值是「实用例子」**）
HBLINE_LINE#13 … len=5 nl=1 visible=4 runs=3 text="​画刷​"          ← 导航项（对照组）
```

* `runs=` 是**字形 run 数**（`_glyphRuns.Count`）⇒ 这些行**都排出了字形**（不是空行、不是 0 宽度被裁）。
* 「实用例子」的 key 核实：`HandyControlDemo_Shared/Properties/Langs/Lang.resx:739 <data name="PracticalDemos"><value>实用例子</value>`、`LangProvider.cs:1041 public string PracticalDemos => Lang.PracticalDemos;` ⇒ 按钮文案**就是**「实用例子」，不是派单书/W52A 写的「实用示例」（**推翻一句**，见 §4）。

### 1.4 读数 ③：**画刷全非空**（推翻 (a)）

`HbLineTrace` 站点 D（`HbTextLine.cs:2513` 一带：`SiteD(_lineStart, this, drawn, _run.Props?.ForegroundBrush)`；`brush == null` 会打成 `<null：等于不画>`）：

```
brush=#FF212121        glyphRuns=1 [r0 face=DejaVuSans.ttf        glyphs=4 chars="实用例子"]     ← 按钮
brush=LinearGradientBrush glyphRuns=1 [r0 face=DejaVuSans.ttf     glyphs=4 chars="样式模板"]     ← 选中页签
brush=#FF212121        glyphRuns=1 [r0 face=DejaVuSans.ttf        glyphs=2 chars="控件"]         ← 页签#2
brush=#FFBDBDBD        glyphRuns=1 [r0 face=DejaVuSans.ttf        glyphs=6 chars="请输入关键字"]  ← Placeholder
brush=#FF212121        glyphRuns=3 [r0 face=DejaVuSans.ttf glyphs=1 chars="​"] [r1 face=NotoSansCJK-Regular.ttc glyphs=2 chars="画刷"] [r2 face=DejaVuSans.ttf glyphs=1 chars="​"]  ← 导航项（对照）
```

* 画刷值齐对：`#FF212121` = `PrimaryTextColor`（`Colors.xaml:25`）；`#FFBDBDBD` = `ThirdlyTextColor`（`:28`，hc `SearchBar` 模板给 Placeholder 的就是它）；`LinearGradientBrush` = 选中态的 `{DynamicResource PrimaryBrush}`（`TabItemStyle` 的 `MultiDataTrigger` 生效的又一证据）。
* **`<null：等于不画>` 一次都没出现**；`DrawInstructionCensus` 的几何行里也见到 `A=0.000` 的**画刷存在但透明**的实例（标题栏按钮），说明这套仪表**能**把"透明画刷"和"没有画刷"分开。
* 桥侧 `SkiaBrush.cs:60-62` 支持 `MilLinearGradientBrush → SKShader.CreateLinearGradient` ⇒ 渐变画刷**不是**障碍（仍列为正极判据之一，见 §3.2）。

⇒ **(a)「Foreground 解析成白/透明」不成立。**

### 1.5 读数 ④：判定点 —— **面计划是对的，画的时候面丢了**

同一趟 `app.log`，`实用例子`/`样式模板`/`请输入关键字` 这几行紧邻的 `[TEXTLINE_DIAG]`：

```
[TEXTLINE_DIAG] R1 面计划：runs=1 {[0,4) /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf#0 w=400/5/0}
                 ⇒ segments=1 0:[0,4) /usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc#0 (按码点回退) slot=1 run=0
HBLINE D#0 … brush=LinearGradientBrush glyphRuns=1 [r0 face=DejaVuSans.ttf glyphs=4 chars="样式模板"]
```

* 计划段 = **NotoSansCJK-Regular.ttc**（"按码点回退"），`slot=1`（`BuildSegmentFaces`（`HbTextLine.cs:4391`）把**主面放在槽 0**、回退面拿槽 1）。
* 而**真正交给 `DrawGlyphRun` 的那张 run 的面是 `DejaVuSans.ttf`** —— 一份**没有 CJK 覆盖**的面。
* 代码路径（逐行读过，行号 = 现树 `build/shims/PresentationCore.HbTextLine.cs`）：

| 位置 | 代码 | 语义 |
|---|---|---|
| `:650` | `HbShapedRun r = HbShaper.Shape(seg.Face.Path, seg.Face.FaceIndex, sub, emSize, language);` | **按"段自己的面"整形** ⇒ 字形 id 属于**段面**（NotoSansCJK） |
| `:2823` | `if (shaped.Chunks == null \|\| shaped.Chunks.Count <= 1)` | 本行走**单段分支**（全 CJK 只落成一段） |
| **`:2826`** | `_glyphRun = BuildGlyphRun(shaped, **glyphTypeface**, …)` | **`glyphTypeface` = 段落主面（DejaVu）** ⇒ 用 A 面的 id 去 B 面取字形 ⇒ **零墨** |
| `:2838-2841` | `GlyphTypeface face = glyphTypeface; if (segmentFaces != null && ch.SegmentIndex … ) face = segmentFaces[ch.SegmentIndex];` | **多段分支按段面取面（正确）** ⇒ 这就是"为什么导航项有墨" |

* 同一解释下"哪些灭、哪些活"**完全对齐**（一趟 43 条逐行读数全量分类，不抽样）：

| 行 | 段数 | 面（实际绘制） | 屏上 |
|---|---|---|---|
| 31 个导航项（`ZWSP+CJK+ZWSP`） | 3 | `NotoSansCJK-Regular.ttc` | **有墨**（69 色 / 10.47%） |
| 页签标题「样式模板」「控件」「工具」 | 1 | `DejaVuSans.ttf` | **零墨**（1 色 / 0.00%） |
| 按钮「实用例子」 | 1 | `DejaVuSans.ttf` | **无字**（8 色 / 0.15% = 圆角 AA） |
| Placeholder「请输入关键字」 | 1 | `DejaVuSans.ttf` | **无字**（19 色 = 只有放大镜图标） |
| 导航尾部 4 项（代码仓库/关于/群友推荐/敬请期待） | 1 | `DejaVuSans.ttf`（其中「敬请期待」是 `DejaVuSans-Bold.ttf`） | **零墨**（派单书/W52A 都没点到） |

（口径：`HBLINE D#` 逐行读数**全量 43 条** = **12 条单段**（面全错，9 个文案）+ **31 条多段**（面全对，每条第 1/3 张 run 是 ZWSP 的 DejaVu、第 2 张是 CJK 的 NotoSansCJK）；不抽样、不按实例合并。）

### 1.6 旁证：`(b)` 的另一种形态也无份

* `GlyphRunCensus` 前 3 帧 `runs=0` —— **不是**"字形没进通道"，而是**前 3 帧只画了窗口非客户区**（`DRAW_CENSUS`：`frame=2 指令种类=2 总执行=14`，全部落在 `设备=(656,1,47x30)`…`(788,588,11x11)` = 标题栏按钮与右下角抓手）⇒ **这两个仪表对本问题天然无射程**（`MaxFrames=3` 吃不到 WPF 内容帧）。如实记为仪器边界，并已改用**不按帧截断**的 `HbLineTrace`/逐行 dump。
* `[LINEHEIGHT] draw cpFirst=0 origin=(0.0000,0.0000) … runs=1/2` ⇒ 全趟只有 2 次**快路径**（`SimpleTextLine`）绘制，且与上述零墨的 12 条记录**无交集**（那些行走的是 shim 托管路径）⇒ 本缺陷**与 `SimpleTextLine` 快路径无关**。

---

## §2 修法

### 2.1 落点（**一处**，最小改动）

`build/shims/PresentationCore.HbTextLine.cs:2823-2826` —— 单段分支改成"**先问计划要面**"，与多段分支 `:2838-2841` **语义同源**：

```csharp
GlyphTypeface singleFace = glyphTypeface;
if (shaped.Chunks != null && shaped.Chunks.Count == 1)
{
    int segSlot = shaped.Chunks[0].SegmentIndex;
    if (segmentFaces != null && segSlot >= 0 && segSlot < segmentFaces.Length && segmentFaces[segSlot] != null)
        singleFace = segmentFaces[segSlot];                      // ← 主路径：取段面（slot 语义见 :4391）
    else if (segmentFaces != null && segmentFaces.Length == 1 && segmentFaces[0] != null
             && plan != null && plan.Segments.Count == 1)
        singleFace = segmentFaces[0];                            // ← 就地面计划（BuildSegmentFacesFromPlan）的等价槽
    else if (plan != null)
        HbFallbackDiag.NoteRunFaceSlotMissing();                 // 有计划却拿不到面槽 ⇒ 记数（不静默）
}
_glyphRun = BuildGlyphRun(shaped, singleFace, pixelsPerDip, baseline, startPenX, shaped.Text);
```

**为什么落在那里**：① 它是**唯一**把"段面的字形 id"与"段面"拆散的地方（`:650` 用段面整形、`:2826` 用主面绘制）；② 多段分支已在做对的事 ⇒ 改动只是把两分支对齐；③ `Count <= 1` 为假时新代码一行都不执行 ⇒ **多段行（31 个导航项）逐字节不变**，这是本修法的零回归判据；④ **不动**度量/断行/记账（宽度与 advance 早已由 `plan.Sub()` + `HbBreakEngine.MeasureChars` 算好，见 `:4043-4046`）⇒ 修后"画的"与"量的"**更一致**（修前是不一致）。
**不改**：应用器、生成物、`known-red.json`、任何判据件、hc 源码、`upstream/**`。

### 2.2 交付形态 = `proposed-fix.diff`（**按主控排程裁定未落地**）

* 文件：`$HOME/w61a/diff/W61A-D-G57-shim-singleface.diff`（42 行；sha16 **`cac51d6f54ad9845`**；对 `PresentationCore.HbTextLine.cs` 做 `patch -p0` 即可）。
* 主控裁定原文（2026-09-21 00:1x）："**修复只交 `proposed-fix.diff` 形式**（如果还没落地就**不要**现在落地——落地后必须两极化，而两极化需要槽）…… 槽让给关键路径"。
* 落地代价（**必须由主控决定**）：动 `build/shims/**` ⇒ `hbtextline` 位变 ⇒ **必须发波**（重取五臂 + 重钉 + 重冻）；实测 PC 重建 **0 警 0 错 28.7 s**，但**五臂/门禁不在本车道写域**。

### 2.3 落地→复原的机械证据（曾落地的那 4 分钟，如实留档）

| 时点 | 件 | sha16 | 字节 |
|---|---|---|---|
| 开工（== `#48` 冻结值） | `build/shims/PresentationCore.HbTextLine.cs` | `e89fed55fd8e32bc` | 290,825 |
| 改动后 | 同上 | `921ba9c65e9fb3be` | 293,165 |
| **复原后** | 同上 | **`e89fed55fd8e32bc`** | **290,825** |
| 开工 | `build/PresentationCore.Linux/bin/Release/PresentationCore.dll` | `9465f9dce39e2dfc` | 3,601,408 |
| 重建后（`HEAVYSLOT=ACQUIRED waited=180s`，`0 个警告 / 0 个错误 / 28.71 s`） | 同上 | `21e3e88a5090cd3b` | 3,601,408 |
| **复原后** | 同上 | **`9465f9dce39e2dfc`** | **3,601,408** |

复原方式 = `cp -p` 回**开工备份**，双证：`cmp $HOME/w61a-backup/PresentationCore.HbTextLine.cs.BEFORE build/shims/PresentationCore.HbTextLine.cs` = **IDENTICAL**；`cmp $HOME/w61a-backup/PresentationCore.dll.BEFORE build/PresentationCore.Linux/bin/Release/PresentationCore.dll` = **IDENTICAL**。
`obj/Release/PresentationCore.dll` 与 `obj/Release/HbTextLineShimSha.g.cs`（构建中间件，**所有判据都排除 `obj`**）也已一并回填成"与复原后源码一致"的内容（`obj` 与 `bin` 在该工程里**逐字节相同**，用未被我碰过的 `PresentationFramework`/`WindowsBase` 现场核对过）。
⇒ **现树里没有我留下的产品位移**（§0 九位表已复算）。

---

## §3 两极化与零回归

### 3.1 负极（**已取**，是本趟唯一实测的极性）

**条件**：`$HOME/w61a/app`（五件见 §0）＋ 显示 `:198` ＋ `Xvfb 1400x1050x24` ＋ 同一脚本 `probe.sh diag1 :198 census`（`W61A_TIMEOUT=95`，槽内）＋ 阈值 = `%k` 与 `fx:standard_deviation`（与 W47A/W52A 同法）。

| 区域（屏幕坐标，来自 W52A 的 `[GEO]`，本趟窗口几何逐项相同） | `colors` | `stddev` | 众数色 | 判读 |
|---|---|---|---|---|
| **页签行** `228x27+318+318` | **1** | **0.00 %** | `#FFFFFF`（6156/6156） | **零墨** |
| **「实用例子」按钮** `203x27+328+284` | **8** | 0.15 % | `#EEEEEE`（5471/5481） | 只有圆角 AA（非众数像素 **10**） |
| **搜索框** `176x27+328+358` | 19 | 2.71 % | `#FFFFFF` | 只有放大镜图标 |
| **导航项（对照）** `203x27+328+391` | **69** | **10.47 %** | `#FFFFFF` | 有墨（人眼可读「画刷」） |
| **下划线带**（本趟新增） `228x4+318+343` | 2 | 22.00 % | `#FFFFFF` | **非众数像素 156（y=345/346 各 116 px `#326CF3`）** |
| 截图 `root.png` sha16 | `9380291b84d81dd6`（**diag1 与 diag2 逐位相同** ⇒ 渲染确定性） | | | |
| 进程终态 | `FINAL alive=yes`、`unhandled=0`；`APP_RC=124`（我自己的 `timeout` 收尾，非崩溃） | | | |

与历史读数对账：`1 / 8 / 19 / 69` 与 **W47A §5（`#46`）**、**W52A §2.1（`#48`）逐位相同** ⇒ `D-G57` 至今**确定性复现**、未被 `D-G55/D-G56` 及之后的波改动。

### 3.2 正极（**未做** ⇒ 配方 + 期望读数 + 判据，供主控按 §3.2 一次跑完）

> 依据主控裁定（"先出结论再补腿"/"不要再排队抢槽"）**未跑**。以下是可直接照抄的配方（**一条获取里跑完**，≈3 min 槽内）：

```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
# ① 落地（备份 → 打补丁）
cp -p $R/build/shims/PresentationCore.HbTextLine.cs $HOME/w61a-backup/PresentationCore.HbTextLine.cs.PRE_POS
patch -p0 -d / < $HOME/w61a/diff/W61A-D-G57-shim-singleface.diff   # 或按 diff 头部两行路径直接 patch -p0
sha256sum $R/build/shims/PresentationCore.HbTextLine.cs | cut -c1-16      # 期望 921ba9c65e9fb3be
# ② 重建 pc（槽内；约 30 s）
export PATH="$HOME/.dotnet:$PATH"; DOTNET_gcServer=0
bash ~/heavy-slot.sh --wait 300 -- timeout 600 dotnet build $R/build/PresentationCore.Linux/PresentationCore.Linux.csproj -c Release -m:1 --nologo -v q
# ③ **只换被测那一件**（不要用 sync-applocal.sh：它会把桥一起换成 79e45aed）
cp -p $R/build/PresentationCore.Linux/bin/Release/PresentationCore.dll $HOME/w61a/app/PresentationCore.dll
# ④ 同条件重跑（与 §3.1 同脚本、同显示、同阈值、同五件的另四件）
W61A_TIMEOUT=90 W61A_SLOTWAIT=300 bash $HOME/w61a/bin/probe.sh diag3 :198 census
for spec in "tabrow 318 318 228 27" "button 328 284 203 27" "searchbar 328 358 176 27" "navitem 328 391 203 27"; do set -- $spec; \
  python3 $HOME/w61a/bin/analyze.py ink $HOME/w61a/logs/diag3/root.png $1 $2 $3 $4 $5; done
# ⑤ 零回归：W55A 两步腿
W55A_STEPS="nav1 tab3" W55A_APP=$HOME/w61a/app bash $HOME/w55a/bin/leg.sh W61A_POS :198 A
```

**期望读数（先写死，跑完照此判）**：

| 判据 | 期望 | 依据 |
|---|---|---|
| ① 页签行 `colors` | **> 1**（且非众数像素 > 0；预期是「样式模板/控件/工具」的字形墨） | 面改对后 CJK 字形有墨 |
| ② 按钮「实用例子」文字可辨 | `colors` **> 8**、非众数像素 **远大于 10** | 同上（该行 `face` 应从 `DejaVuSans.ttf` 变 `NotoSansCJK-Regular.ttc`） |
| ③ 搜索框 Placeholder 有墨 | `colors` **> 19** | 同上（`#FFBDBDBD` 的 6 个 CJK 字形） |
| ④ **零回归（强判据）** | 导航项 `colors=69 / stddev=10.47%`、非众数像素 **= 303** ⇒ **逐位不变**；下划线 `y=345/346` 的 `#326CF3` 逐像素不变；`root.png` 除上述三区外**逐字节相同** | 多段分支一行未执行 |
| ⑤ 反极性（若同时要取） | 复原 shim + 复原 `pc`（`cp -p` 备份件）⇒ `colors` **回到 1 / 8 / 19**、`root.png` sha16 回到 **`9380291b84d81dd6`** | 本趟 §3.1 已是"修前"读数 |
| ⑥ 槽纪律 | 任一件 `rc=137` 或 `HEAVYSLOT=TIMEOUT` ⇒ **该对读数作废、重取**（不当缺陷证据） | 主控 2026-09-21 裁定 |
| ⑦ 仪器旁证（可选，最省事） | 修后 `HbLineTrace` 站点 D 里 `实用例子/样式模板/控件/工具/请输入关键字` 的 `face=` 应变成 **`NotoSansCJK-Regular.ttc`**（这是**机制级**判据，一条 grep 即可） | §1.5 |

**未做/未取（如实）**：正极三格、零回归腿、反极性复跑、`W62A` 重发桥之后的件组合下的重测、31 个导航页里同族零墨文本的普查（预测：**页面内"整行 CJK 且无拉丁/无隐形 run"的文本同样零墨**，本次窗口右页是图片演示页 ⇒ 未见反例）。

---

## §4 我推翻的既有说法（逐条）

1. **推翻 W52A §2.5①/§7 的"选中页签整块零绘制、连 2px 下划线都没落屏、27 行逐行非众数像素全 0"** —— 下划线在 `y=345/346`（各 116 px `#326CF3`），他们的裁剪区 `228x27+318+318` 只到 `y=344`。**⇒ `D-G57` 不是"整块零绘制"，而是"只有文字零墨"**（派单书/预登记里那句"整块零绘制（已收窄）"同样被推翻）。
2. **推翻 W52A §2.3 的"排除空串"论证** —— 他们的依据是"页签 74 px = `Padding 10,5`×2 ＋ 内容 54 px"；但 `TabControlInLine` 模板的 `headerPanel` 是 **`UniformGrid Rows=1`**（`Themes/Styles/TabControl.xaml:112`）⇒ 页签等宽是**容器分配**的结果、与内容宽无关，**该论证不成立**。不过**结论仍不对**（不是空串，是面错）——本趟改用**进程内**证据（§1.3）定死。
3. **推翻派单书与预登记 §7.2 的 (a)/(b) 二分**：(a) 画刷、 (b) 未进通道**都不是**；真判定点是 `HbTextLine.cs:2826` 的**面色不匹配**（第三形态）。
4. **推翻「实用示例」这个按钮文案** —— lang 真值是 **「实用例子」**（`Lang.resx:739`）。
5. **修正"三处 `{ex:Lang}`"的计数**：同一缺陷在本次窗口里实际命中 **12 条绘制记录 / 9 个文案**，除派单书点的 3 处外，还有**导航尾部 4 项**（代码仓库/关于/群友推荐/敬请期待）。而"导航项有字"的对照组也不是"`{ex:Lang}` 的 Binding 分支更健康"——**两组的 `{ex:Lang}` 都正常**，差别**只在**"整行落成 1 段还是多段"。
6. **修正一处仪器口径**：`GlyphRunCensus`/`DrawInstructionCensus` 的前 3 帧**只覆盖窗口非客户区**（本趟实测 `总执行=14`），拿它们查"页签区域有没有绘制指令"**必然误判** —— W52A §4 说"即便开也答不了 (b)"是对的，但原因是**帧窗**而不是"预检不带几何"。

---

## §5 复算命令（逐条可粘贴）

```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
# 0) 两侧读数（负极）—— 本报告 §3.1 就是这两趟
W61A_TIMEOUT=95 W61A_SLOTWAIT=900 bash $HOME/w61a/bin/probe.sh diag1 :198 census
W61A_TIMEOUT=90 W61A_SLOTWAIT=900 bash $HOME/w61a/bin/probe.sh diag2 :198 trace
# 1) 四区像素（同一脚本同一阈值）
for spec in "tabrow 318 318 228 27" "button 328 284 203 27" "searchbar 328 358 176 27" "navitem 328 391 203 27" "underline 228 4 318 343"; do
  set -- $spec; python3 $HOME/w61a/bin/analyze.py ink $HOME/w61a/logs/diag1/root.png $1 $2 $3 $4 $5; done
python3 $HOME/w61a/bin/analyze.py rows $HOME/w61a/logs/diag1/root.png 318 318 228 27      # 逐行墨量（27 行全 0）
# 2) 下划线落屏（§1.2 的两行）
python3 - <<'PY'
from PIL import Image
px=Image.open('/home/links-dev/w61a/logs/diag1/root.png').convert('RGB').load()
for y in range(340,349):
    xs=[x for x in range(300,570) if px[x,y]!=(255,255,255)]
    print(y, len(xs), ('#%02X%02X%02X'%px[xs[0],y]) if xs else '-')
PY
# 3) 判定点三行（§1.5）—— 一趟 grep 就够
L=$HOME/w61a/logs/diag2/app.log
grep -a 'R1 面计划' $L | head -3                                  # 计划 = NotoSansCJK（按码点回退）slot=1
grep -a 'HBLINE D#' $L | sed 's/HBLINE D#0 cpFirst=0 //'          # 43 行：12 单段（face=DejaVu*=错面=灭）/ 31 多段（第2张run = NotoSansCJK=活）
grep -ac 'HBLINE D#' $L; grep -a 'HBLINE D#' $L | grep -ac 'face=DejaVuSans'
# 4) 逐行 dump（§1.3，含 text= 与 runs=）
grep -a 'HBLINE_LINE#' $HOME/w61a/logs/diag2/hbline.log | sed 's/ start=0 cpFirst=0//' | head -20
# 5) 修法 diff（未落地）
sha256sum $HOME/w61a/diff/W61A-D-G57-shim-singleface.diff | cut -c1-16      # cac51d6f54ad9845
# 6) 复原证（§2.3）
cmp $HOME/w61a-backup/PresentationCore.HbTextLine.cs.BEFORE $R/build/shims/PresentationCore.HbTextLine.cs && echo SHIM-IDENTICAL
cmp $HOME/w61a-backup/PresentationCore.dll.BEFORE $R/build/PresentationCore.Linux/bin/Release/PresentationCore.dll && echo PC-IDENTICAL
# 7) 本报告自身 sha16
sed '/^> 报告自身 sha16 = /d' $R/build/MilBridge/W61A-report.md | sha256sum | cut -c1-16
```

---

## §6 边界 · `NOINFO` · 未覆盖（不许当绿，也不许当红）

| # | 项 | 状态 |
|---|---|---|
| 1 | **正极性（修后四区读数）** | **未做**（排程裁定）⇒ 配方/期望/判据见 §3.2 |
| 2 | **反极性复跑**（落地⇒复原⇒再落地） | **未做**；但"修前 = 负极"本趟已实测（§3.1），且复原证是 `cmp` 双证 |
| 3 | **零回归腿**（`W55A` 两步 / `nav1 tab3`） | **未做**（需槽）⇒ 命令已写死 |
| 4 | 选中页签 `LinearGradientBrush` 字形能否落屏 | **未验证**（桥侧 `SkiaBrush.cs:60-62` 有 `CreateLinearGradient`，但"渐变画刷的**字形**绘制"没有独立读数）⇒ 列进正极判据③/④ |
| 5 | 31 个导航页内的同族零墨文本 | **未普查**（预测：同族；本趟窗口右页是图片演示页） |
| 6 | 修后是否改变**度量**（宽度/行高/换行） | **未测**（本修法只改"绘制用哪份面"；宽度早已由 `plan.Sub()` 度量）；`FrameProbe`/`PcLineOracle` 等对拍未跑 |
| 7 | `D-G57` 在**别的世代**（`#46`/`#47`）是否同一判定点 | **未回溯**（本趟只读现树 `hbtextline=e89fed55fd8e32bc`，该 shim 与 `#48` 冻结值相同 ⇒ 至少 `#48` 同族） |
| 8 | 「敬请期待」用的是 `DejaVuSans-Bold.ttf`（粗体面） | 已记录，未深究（同类错面，不影响判定） |
| 9 | `INPUT_TRACE`（`Text` DP）本次**未用于定因** | 其 2,220 行里 `dp.Name=="Text"` 的写/读格被 W7 辅助格额度挤占（仪器预算现象），**本报告不据此下任何结论** |

**仪器边界（继续有效）**：`GlyphRunCensus`/`DrawInstructionCensus` 只打前 3 帧（本趟实测前三帧只有窗口非客户区）⇒ **凡"某区域有没有绘制指令"的问题，禁止用这两个仪表**；本趟改用 `HbLineTrace`（不按帧截断）+ shim 逐行 dump。

---

## §7 给主控的交接（≤6 行大白话）

1. **零墨（`D-G57`）不是"画刷太浅"，也不是"没画"**：页签那条选中下划线其实**是画上去了**（`y=345/346` 两行蓝），W52A 说"连下划线都没落屏"是他们裁的框差了两个像素。
2. 真正的原因是**画字时用错了字体**：排版时程序**已经**算出"这几个中文要用 NotoSansCJK"，但真去画的时候却交给了 DejaVu（一份没有中文字的面），于是**一个墨点都没有、也不报错**。
3. 一行代码的问题：`build/shims/PresentationCore.HbTextLine.cs:2826`（单段行恒用主面）；**多段行**走的是 `:2838-2841`，面取对了 —— 这就是"为什么左边导航列表有字、页签/按钮/搜索框没字"的全部差别（同一趟 43 条逐行读数全量对齐）。
4. 影响面比登记的更大：本次窗口里**9 个文案 / 12 条绘制记录**的中文字全灭（3 个页签 + 按钮「实用例子」+ 搜索框提示 + 导航尾部 4 项），不只是派单书点的 3 处。
5. 修法我按您的排程裁定**只交 diff**（`$HOME/w61a/diff/W61A-D-G57-shim-singleface.diff`，`cac51d6f54ad9845`）：落地点过、重建过（`pc 9465f9dc→21e3e88a`，0 警 0 错 28.7 s），**随后逐字节复原**，现树九位里**没有我留下的位移**（`hbtextline e89fed55fd8e32bc`、`pc 9465f9dce39e2dfc`，`cmp` 双证）。
6. 下一步（`#50`）只需**一条槽**：打 diff → 重建 PC → 只换 `PresentationCore.dll` → 同脚本重跑 ⇒ 判据是"页签 `colors>1`、按钮/搜索框有墨，且**导航项 69/10.47% 与下划线逐像素不变**"；动 shim ⇒ `hbtextline` 位变 ⇒ **必须发波**，这步请您定。

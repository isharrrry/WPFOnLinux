# P1-tail2 · `T-A24` · 新线：两页仍空白 —— 阻塞归属侦察 ＋ 选靶（**只读侦察件**）

> **本件 `T-A24`（只读侦察子代理）交付。写域**：**唯一**新建件 ＝ 本载体 `build/MilBridge/P1-tail2-blank-recon.md`。
> **未改任何仓内文件**（不碰 `src/**`、`build/MilBridge/tools/**`、装置件、在册证据目录、`docs/**`）；**未构建**；**未跑整趟 `verify-all`**；**未跑 `static-jaws-check.sh`**；**未跑腿、未占显示位**；未 `git add/commit/push`。
> **口径**：一切读数**本席现取**（`sha256sum`／`nm`／`wc`／`grep -c`／`cmp`／`compare`／`python3` 只读 PNG）；**未抄任何既有报告的读数**（引用他人件处逐条标「未独立复算」）。**行号一律「仅本次有效」**，引件给内容锚。
> **代际（现取）**：`src/WpfGfx.Linux.Native/bin/libwpfwin32.so` ＝ **`e09c8d739c179966`**｜`nm -D --defined-only … | wc -l` ＝ **674** ＝ `bin/exports.txt` 行数 **674**｜`nm … | grep -c 'FsQueryTextDetails$'` ＝ **1**｜`src/WpfGfx.Linux.Native/src/win32_pts.c` ＝ **`74aa285b641de4a6`**｜`HEAD` ＝ `584f20a`（`P1 尾波2 (#82)：T-A23 重取臂③…`）。
> **被侦察的证据目录（T-A23 落，本席只读）**：`build/MilBridge/tests/PtsPagesProbe/evidence-tail2c/`（有 WM 腿）＋ 其子目录 `nowm/`（无 WM 腿）。

---

## §0 结论速览（自包含）

1. **① 帧内容身份 ＝「空态占位页」，不是目标页**（**像素级**判定）：`shots/g1/{boot,k23,k24,last}.png` 的内容区里，**恰好有一块 416×312 的矩形**（`(317,137)–(733,449)`）**逐像素**等于 `under_construction.gif` **第 0 帧**（`NEAREST` 放大 **×1.04**）：`129792/129792` 像素相等、**最大曼哈顿差 ＝ 0**；该 GIF ＋ 其下方 `98×25` 的 **4 字大号文字块**（`(475,467)–(572,491)`，1116 暗像素）＝ 第三方 demo 的 **`UnderConstruction`（「敬请期待」）**空态控件。⇒ 帧画的是**空态页**，**不是** `FlowDocumentDemo`（Neptune 文档 ＋ 三页签）／`RichTextBoxDemo`（400×300 富文本框）的内容。
2. **② 导航 ＝ 到达「类型层」，未到达「像素层」**：目标页**真的被打开**（`[NS] loaded …FlowDocumentDemo` / `…RichTextBoxDemo`；`[GEO]` 现取到目标页**自有**的三个 `TabItem`（`hdr=流文档滚动视图／单页视图／查看器`）与其工具栏 `Slider`）；但 `boot↔k24` 的像素差 bbox ＝ **`(28,169,240,561)`（＝左栏 ListBox 区）**，**内容区（x>240）零像素变化**。
3. **③ 绘制路径 ＝ 停在「托管 PTS 段落客户端取内容／校验」这一层，未到 MIL 命令／画刷／通道／DV 几何／文本行**：现取 `[HC-UNHANDLED]` **427** 行**全部**为 `PtsException: Page formatting engine did not complete formatting operation. Error code: '-10000'`（首帧 `MS.Internal.PtsHost.UnsafeNativeMethods.PTS.Error(…)`），对应 `[FS_PAGE_GAP] rc=-10000 reason=unclaimable-para entry=FsQueryTextDetails`（**53/53**）与 `[FSQSTD] reason=unclaimable-subtrack`（**370**）。**下游那几层在同一帧里对其余内容工作正常**（左栏 ListBox 高亮/滚动**有**像素位移、窗口框/左栏/占位 GIF 都画得出）⇒ 「非 PTS 面（MIL／画刷／通道／DV）」这一假设**被否证**（§4.4）。
4. **④ 选靶 ＝ 唯一增量（native 侧）**：在 `src/WpfGfx.Linux.Native/src/win32_pts.c` 做「**查询期内容模型**」增量（具名 `NATIVE-QUERY-PHASE-CONTENT-MODEL` ＝ `T-A21` §5.3 的 `(乙)＋(丙‑1)` 合成），使两个查询入口**不再返 `unclaimable-*`**。理由 ＋ 判据草案（4 条可证伪 ＋ 反极性）见 §5；「合法终点」另给（§5.3）。
5. **⑤ 具名 `NOINFO` 8 条**（§6）。其中两条是本趟**新读出的结构事实**、不是猜测：
   - **主机侧确实对这次切页做了响应**（`[GEO]` 现取：`MainContent` 的 `BorderTitle` 由 `wh=0x0 vis=False`（`_isFull=true`）变为 `wh=29x25 vis=True`（`_isFull=false`）），**但帧上连标题栏都没有像素** ⇒ 「内容面板的像素停在切页之前那一态」。
   - **帧上目标页的 TabItem 位置没有任何像素**（`y∈[40,86] ∧ x∈[258,790]` 内暗像素 **0**），而同一位置在 `[GEO]` 里是 `vis=True` 的三个 `TabItem`。

---

## §1 证据 · 装置 · 指纹（现取）

| 件 | `sha16` | 备注 |
|---|---|---|
| `evidence-tail2c/app_g1.log` | `ad64b4f88dc6fc73` | 7199 行；有 WM 腿 |
| `evidence-tail2c/session.txt` | `4b962e0f6d20bd38` | 腿/点击序/帧行 · 现取原文见 §2.4 |
| `evidence-tail2c/leg_23.env` / `leg_24.env` | `9e68a0dea4e4a507` / `2f5901ddbd6ddb84` | `ns=…RichTextBoxDemo` / `…FlowDocumentDemo` |
| `evidence-tail2c/shots/g1/boot.png` | `b21eb530afd3c66c`（190413 B） | |
| `evidence-tail2c/shots/g1/{k23,k24,last}.png` | 三件同值 **`ef3fd6765f18f51b`**（各 189716 B） | 三帧**逐字节相同** |
| `evidence-tail2c/nowm/shots/g1/{k23,k24,last}.png` | `9ddd25ab947d0efb` | 无 WM 腿（装置差，非本件结论承重件） |

**在册对照（本席现取 `cmp`）**：`evidence/shots/g1/k24.png` 与 `evidence-tail2c/shots/g1/k24.png` ⇒ **IDENTICAL**（逐字节相同）⇒ 本趟帧面**零位移**。
**腿身份（现取 `session.txt`）**：`clicks=[24,23]`（**先 24 后 23**）；`shim=e09c8d739c179966 pf=1757d610a687777c`；两腿 `LEGS_RUNNER=PASS requested=2 obtained=2 refused=0`。
**方法边界**：本席**未**重跑腿、**未**占显示位；`[GEO]`／日志面读数是**文件内容**（`sha16` 已给），帧面读数是**只读 PNG 解码**。第三方 demo 源（`~/hc-linux/src/Shared/HandyControlDemo_Shared/**`）**只读 grep/sed**，**未写、未运行**。

---

## §2 ① 帧内容身份（像素级）

### 2.1 主判定：内容区里那块矩形 **＝ `under_construction.gif` 第 0 帧**（逐像素）

```
$ python3 （只读 PNG + 只读 GIF）
  在 k24.png 里，凡颜色 ∈ GIF 全 100 帧调色板（102 色）的像素集合
    ⇒ 恰好是一个**实心矩形**：bbox=(317,137,732,448)，面积=129792，计数=129792（100% 填充、矩形外零命中）
  取 GIF 第 0 帧 → NEAREST 放大到 416×312 → 放到 (317,137) 逐像素比对：
    ⇒ eq = 129792/129792 = 1.0000，最大曼哈顿差 = 0
```
⇒ **内容区那一块 416×312 的图像，逐像素就是第三方 demo 的 `Resources/Img/under_construction.gif` 第 0 帧**（放大率 `416/400 = 312/300 = 1.04`）。
（`under_construction.gif` ＝ 400×300、100 帧、98 色调；其首要色 `(193,138,117)/(195,137,117)/(205,152,127)…` 与帧内该块**逐色同值**。）

### 2.2 该 GIF 的「归属控件」＝ `UnderConstruction`（「敬请期待」空态）＋ 几何自洽

现取（第三方 demo 源，**只读**）：
- `UserControl/Main/UnderConstruction.xaml`：`Border(Background=RegionBrush, CornerRadius=4)` → `hc:TransitioningContentControl` → `StackPanel Margin=32` → **`hc:GifImage Width=400 Height=300`**（`BitmapImage UriSource=…/under_construction.gif`）＋ **`TextBlock Margin=0,16,0,0 HorizontalAlignment=Center Text={…LangKeys.ComingSoon}`**。
- `UserControl/Main/PracticalDemo.xaml`：**唯一** `<userControl:UnderConstruction VerticalAlignment="Center" HorizontalAlignment="Center"/>`（全树 `grep -rn UnderConstruction --include=*.xaml` ＝ **仅此一处**）。

**帧上另两处与上件逐条对上**：
1. **图片**：416×312 实心块（＝ GIF 400×300 放大 ×1.04）——§2.1。
2. **文字**：GIF 下方紧邻的 `98×25` 暗像素块（`(475,467)–(572,491)`，1116 暗像素）＝ **4 个大号汉字**（`TextBlockLargeBold`，`Margin="0,16,0,0"`）＝ `LangKeys.ComingSoon`（**敬请期待**）；位置在图片正下方、水平居中 ⇒ 与 `StackPanel` 的版面**逐条自洽**。
3. **几何**：把该 `StackPanel`（图片 400×300 ＋ 16px 间距 ＋ 约 40px 文字行 ＋ 32px 内边距）居中，得到的图片中心 ≈ `(525,293)`；实测图片中心 `(525,293)`。

### 2.3 与两页「应有内容」对照 —— 一个都对不上

| 页 | 应有内容（现取第三方 XAML 原文） | 帧上现取 |
|---|---|---|
| `k=24` `FlowDocumentDemo` | `hc:TransitioningContentControl` → **`TabControl` ＋ 3 个 `TabItem`**（`FlowDocumentScrollViewer`／`PageViewer`／`Reader`，各 `Width=640 Height=400 Margin=32`）承载 **Neptune 长文档**（含 `<Figure Background="GhostWhite">`／`<Floater Background="GhostWhite">`／`<Table>` 的 `LightGoldenrodYellow`·`LightGray` 行／`<Hyperlink>`） | 只有：GIF 块 ＋ 「敬请期待」＋白/灰底；**Neptune 文档的具名色锚命中 0**（守卫现取 `GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0`）；`grep -ci neptune app_g1.log` ＝ **0** |
| `k=23` `RichTextBoxDemo` | `hc:TransitioningContentControl` → **`RichTextBox Width=400 Height=300 Margin=32`**（标题重复 20 次 ＋ 正文重复 1000 次 ＋ 超链接） | 同上一栏**逐字节相同**（`k23.png ≡ k24.png`） |
| 首屏 `PracticalDemo` | `<UnderConstruction/>`（**就是**「敬请期待」空态） | **帧上正是它** |

⇒ **判**：帧画的是**首屏 `PracticalDemo` 的空态占位页**；**`k=23`／`k=24` 两页都没有任何自己的像素**。

### 2.4 机读面（现取原文，逐条给取法）

```
$ head -20 evidence-tail2c/session.txt                        # 现取（点击序为 [24,23]）
BEFORE item=24 nm=FlowDocument stable=yes rect=28,410,203x27 point=127,423 expect=FlowDocumentDemo try=2
AFTER  item=24 alive=yes ns=HandyControlDemo.UserControl.FlowDocumentDemo ns_delta=1 try=2 expect_hit=yes
CLICK k=24 … AE=15386 pts_unavail=0 pts_gap=0 guard=185 fatal=0 unh=0 ns_last=HandyControlDemo.UserControl.FlowDocumentDemo
FRAME k=24 fr_file=k24.png fr_sha=ef3fd6765f18f51b fr_lsha=ef3fd6765f18f51b fr_ae_boot=15386
--- G1 click 23 ---
AFTER  item=23 alive=yes ns=HandyControlDemo.UserControl.RichTextBoxDemo ns_delta=1 try=1 expect_hit=yes
CLICK k=23 … AE=0 … ns_last=HandyControlDemo.UserControl.RichTextBoxDemo
FRAME k=23 fr_file=k23.png fr_sha=ef3fd6765f18f51b …
$ compare -metric AE …    # 现取
AE(boot,k24)=15386   AE(k23,k24)=0   AE(boot,k23)=15386
$ python3 逐像素求 boot↔k24 差异 bbox ⇒ (28,169,240,561)   # 落在左栏 ListBox 区（ListBox 现取 scr=28,166 wh=203x389）
$ python3 在 (317,137)+(416×312) 比对 GIF 第 0 帧 ⇒ eq=129792/129792=1.0000（最大曼哈顿差 0）
$ python3 在 y∈[40,86] ∧ x∈[258,790] 数暗像素（<150）⇒ **0**（目标页 TabItem 现取所在带，帧上无像素）
```
**无 WM 腿对照（现取）**：该块同样存在、同样 `129792` 像素、同尺寸 416×312，位置 `(557,349)–(972,660)`（装置差导致窗口位移）⇒ 论断**不依赖 WM**。

---

## §3 ② 导航／交互到达性

### 3.1 「到达」的证据（类型层 / 布局层）

| # | 现取证据（文件＋内容锚） | 它证明什么 |
|---|---|---|
| A1 | `[NS] loaded HandyControlDemo.UserControl.FlowDocumentDemo scope=NameScope …`（`app_g1.log`，现取紧随 `[HC-UNHANDLED] #2` 之后）；同形一行 `…RichTextBoxDemo…` | 目标 `UserControl` 的 **`Loaded` 路由事件已触发**（该行由应用侧的 `UserControl.LoadedEvent` 类处理器发出）⇒ 该控件**已被挂进有呈现源的树** |
| A2 | `[GEO]` 现取（blk 12–16，＝ 点 24 之后）：`TabItem#- scr=268,49 wh=165x27 en=True vis=True htv=True hdr=流文档滚动视图 sel=True`／`…scr=440,49 … hdr=流文档单页视图 sel=False`／`…scr=611,49 … hdr=流文档查看器 sel=False` | 这是 **`k=24` 页自己的**三个页签（`FlowDocumentDemo.xaml` 的三个 `TabItem`），**已进入主窗口的视觉树、已有非零布局**（`GeoWalk` 是对主窗口做 `VisualTreeHelper` 深度优先遍历） |
| A3 | 同 `[GEO]` 块：`RepeatButton#- scr=705,439 wh=20x20`／`Slider#- scr=726,440 wh=180x18 val=100`／`RepeatButton#- scr=773,440 wh=126x18`／`RepeatButton#- scr=914,439` | 这是 `FlowDocumentScrollViewer` **自带工具栏**（含缩放 `Slider`）的布局 ⇒ 第 24 页的文档查看器**已实例化并布局到工具栏一级** |
| A4 | 点 23 之后的 `[GEO]` 块（blk 17–20）里 **`hdr=流文档*` 三行全部消失**（且无新 `TabItem`） | 与 `RichTextBoxDemo`（**无** `TabControl`）一致 ⇒ 这两页**确实各按各的树换过** |
| A5 | `[STATE]`／`leg_*.env`：`LB(ListBoxDemo sel=-1/31) → sel=24/31 → sel=23/31`；`AFTER item=2x … ns_delta=1 … expect_hit=yes` | 交互（点击）**打到了目标项**，且应用自报页身份命中期望值 |

### 3.2 「未到达」的证据（像素层）

| # | 现取证据 | 它证明什么 |
|---|---|---|
| B1 | `compare -metric AE boot.png k24.png` ＝ **15386**；逐像素差异 **bbox ＝ `(28,169,240,561)`** ⇒ **全部落在左栏 ListBox 区** | 内容区（x>240）在 boot→k24 之间**一个像素都没变** |
| B2 | `k23.png ≡ k24.png`（`cmp` 逐字节相同，`sha16` 同值）＋ `AE(k23,k24)=0` | 两页之间**也没有任何像素位移** |
| B3 | 帧上**目标页 `TabItem` 所在带**（`y∈[40,86]`，`x∈[258,790]`，取自 A2 的 `scr=`）暗像素 **0** | 目标页页签**没有画出来**（**frame 与 A2 直接冲突** —— 见 §3.3） |
| B4 | 帧上**连 `MainContent` 的标题栏都没有像素**：`BorderTitle` 现取 `Background=TitleBrush`、`Height=32`、位于 `Grid.Row=0`（`MainContent.xaml`）；`[GEO]` 里它此刻 `vis=True`、其两个子按钮 `scr=274,52`／`748,51` 有非零尺寸（§3.3）；而 `x=400` 处 `y∈[32,103]` 的整段是**单一** `(238,238,238)` | 卡住的不只是"某一页"的内容，而是**整个内容面板**（`MainContent` 子树）的像素 |

### 3.3 关键新读数：主机侧**确实**对这次切页做了**布局**响应，但像素没跟上

`MainContent.xaml.cs:37 FullSwitch(bool)`（第三方 demo 源，现取原文）：`_isFull=true` ⇒ `BorderTitle.Collapse()` ＋ `GridMain` 拉伸 ＋ `PresenterMain.Margin=0`；`_isFull=false` ⇒ `BorderTitle.Show()` ＋ `GridMain` 居中 ＋ `Margin=0,0,0,10`。

`[GEO]` 现取（**成对**）：
```
blk 11（点之前，PracticalDemo 期）:  ToggleButton#- scr=268,49 wh=0x0 en=True vis=False chk=False
                                    Button#-       scr=268,49 wh=0x0 en=True vis=False
blk 12–16（点 24 之后，FlowDocumentDemo 期）:
                                    ToggleButton#- scr=748,51 wh=27x27 en=True vis=True chk=False
                                    Button#-       scr=274,52 wh=29x25 en=True vis=True
```
⇒ **`_isFull` 由 `true` 翻成 `false`**，`BorderTitle` 由 `Collapse` 变 `Show` 且**拿到了非零布局** ⇒ **`FullSwitch` 真的跑了、布局真的重算了**。**可是帧上那个位置没有 `TitleBrush` 的任何像素**（B4）。
⇒ **判**：**布局／主机侧响应成立；像素（呈现）没有跟上**。这条与 B1（内容区 0 像素变化）**互证**：面板像素停在**切页之前那一态**（＝ `_isFull=true`、`BorderTitle` 折叠、`PracticalDemo/UnderConstruction` 居中那一态）—— 帧上"没有标题栏"正与"折叠态"一致，而**当前**布局已是"显示态"。

### 3.4 派单里点名的 `asr`／`nav` 面（**具名 `NOINFO`**）

现取 `grep -rln 'asr' build/MilBridge/tools/ build/MilBridge/tests/PtsPagesProbe/` ⇒ **零命中**（`nav=` 亦零命中；装置件里只有 `navclick.py` 这个名字）。⇒ 本件**取不到** `asr`／`nav` 机读面 ⇒ 记为 `NOINFO-1`（§6），**不以 `ns=` 代指**。

---

## §4 ③ 绘制路径定位（**逐层**）

### 4.1 分层表（每层给现取证据与判）

| 层 | 本层现取证据 | 判 |
|---|---|---|
| **（0）输入/命中** | `[HCIN] preMouseDown src=Border#Bd(bg=#FFEEEEEE) < ListBoxItem … < VirtualizingStackPanel < ItemsPresenter < … `；`[STATE] … sel=24/31 → sel=23/31` | **正常** |
| **（1）托管布局/校验（PTS 段落客户端）** | `[HC-UNHANDLED]` **427** 行，**全部** `PtsException: Page formatting engine did not complete formatting operation. Error code: '-10000'`，首帧 `MS.Internal.PtsHost.UnsafeNativeMethods.PTS.Error(Int32 fserr, PtsContext ptsContext)`；`[FS_PAGE_GAP]` **53/53** `rc=-10000 reason=unclaimable-para entry=FsQueryTextDetails para=0x4 out=UNWRITTEN bytes=0`；`[FSQSTD]` `reason=unclaimable-subtrack` **370**（另 `reason=ok` **535**、`claimed-by-provenance-no-content-model` **2**、`null-subtrack` **2**） | 🔴 **在这里断**（异常在**布局/校验期**抛出，被应用侧 `InstallUnhandledGuard` 以 `e.Handled=true` 吞下） |
| **（2）DV 几何 / 文本行** | 与（1）同源：`[FSQSTD-SRC] … NOINFO=fsupdinf(no-source),fsrc(declared-geometry)`；`[FSQSPL] … NOINFO=subtrack-para-geometry(dvrUsed/dvrTopSpace/bbox=0)` | **未产出**（因（1）未过） |
| **（3）MIL 命令 / 画刷 / 通道** | 同一帧里：左栏 ListBox **有**像素位移（B1：`AE(boot,k24)=15386` 全在 ListBox 区；`[GEO]` `ListBox#ListBoxDemo … sel=24→23`）、窗口框/标题区/左栏/占位 GIF＋「敬请期待」**都画得出**（§2） | **本层工作正常**（对**其余**内容；对目标页则**根本没收到命令**——见 §4.4） |

### 4.2 `[HC-UNHANDLED]` 的**分类**（现取，不折口径）

```
$ grep -c '^\[HC-UNHANDLED\]' app_g1.log                       ⇒ 427
$ grep -c 'did not complete formatting operation' app_g1.log    ⇒ 427
$ grep -c 'PtsException' app_g1.log                             ⇒ 427      ← 100% 单一类型
$ grep -c 'entry point named' app_g1.log                        ⇒ 0        ← ENFE（缺符号面）已归零
```
⇒ **427／427 全是同一型 `PtsException('-10000')`**；**没有** `EntryPointNotFoundException`（与 `T-A23` 的读数一致：上一代的 ENFE 面已消）。
口径：「`ENFE_TOTAL`（缺符号面）」与「`[HC-UNHANDLED]`（托管未处理异常面）」**各自定义、不得互折**（本件两值：**0** vs **427**）。

### 4.3 `[GEO]` 侧（目标页的**布局**在、**像素**不在）

- **在**：`TabItem#- … hdr=流文档滚动视图/单页视图/查看器 … vis=True`（blk 12–16）；工具栏 `Slider#- … val=100`。
- **不在**：帧上这些 `scr=` 位置**零暗像素**（§2.4）；**连标题栏也没像素**（§3.3）。
- ⇒ `[GEO]` 反映的是**布局面**（`IsVisible` ＋ `ActualWidth/Height` ＋ `PointToScreen`），**不是**"有没有被光栅化"。本件据此把「布局在 / 像素不在」判为**两个不同的面**（这正是裁定族里"不得把 `ns=`／布局当绘制证据"的同一条）。

### 4.4 「非 PTS 面」假设 —— **被否证**

派单请定位「非 PTS 面」的剩余阻塞。现取的答案是：**否证**。
- 若阻塞在 **MIL 命令／画刷／通道**：无法解释**同一帧**里 ListBox 高亮/滚动**有**像素位移、窗口框与左栏与占位图**都画得出**（§4.1-（3））。
- 若阻塞在 **DV 几何／文本行**：这两层**要先有（1）的几何**才谈得上（`[FSQSTD-SRC] NOINFO=fsrc(declared-geometry)`）；现取 `[FS_PAGE_GAP] out=UNWRITTEN bytes=0` ⇒ **（1）就没过**。
- 现取**没有**任何 MIL/绘制指令侧标记：`grep -ioE 'MIL|GlyphRun|DrawInstruction|Skia|RenderTarget' app_g1.log` ⇒ **零命中**（早先 `grep -ci` 的 92 命中来自 `ItemsPresenter/ScrollContentPresenter/ContentPresenter` 里的 `Present` 子串，不是渲染层标记）⇒ 「MIL 层是否收到命令」本件**取不到**（`NOINFO-6`），但**已足以下判**：（1）断了，下游无从谈起。

---

## §5 ④ 唯一选靶 ＋ 理由 ＋ 判据草案

### 5.1 唯一增量（具名）

> **`NATIVE-QUERY-PHASE-CONTENT-MODEL`**（＝ `T-A21` §5.3 设计草案 `(乙)＋(丙‑1)` 的合成）：
> 在 `src/WpfGfx.Linux.Native/src/win32_pts.c` 上，把「子段内容模型」**在造型窗内建好并缓存到本侧台账**，并在 `FsQuerySubtrackParaList` 的 `pfspara` 里**交回本侧自有的子轨对象**，使 `FsQuerySubtrackDetails`／`FsQueryTextDetails` 在**查询期**能 `rc=0` 答出（而不是 `unclaimable-subtrack`／`unclaimable-para`）。
> **三处落点**：`win32_pts.c`（窗内递归枚举＋本侧对象＋窗外汇总）／`wpf_pts_sub_claim` 的身份模型（接受"本 run 由 `+136/+144` 枚举交回的句柄"）／`bin/exports.txt`（若增导出）。**不涉**托管 `.cs`、**不涉**生成器 `PTSCACHE_EDITS`、**不涉** `FSCBK` 布局。

**理由（逐条，均有本件现取证据）**：
1. 现取的"断点"**唯一**落在（1）层：`[HC-UNHANDLED]` 427/427 全是 `PtsException('-10000')`，而它的 native 侧具名来源就是 `[FS_PAGE_GAP] reason=unclaimable-para`（53/53，`para=0x4`）与 `[FSQSTD] reason=unclaimable-subtrack`（370）——即**入参身份不可认领**。
2. 该层的**下游全层**在同帧内被证明**健康**（§4.4）⇒ 把（1）修通是**唯一**能同时解释"两页零像素"与"其余内容正常"的增量。
3. `T-A21` 已判定**托管侧无可做项**（句柄已产出/已交出/反查面在位），**解除条件全在 native 写域** ⇒ 选靶必须落 native（本件不重复其推导，**标「未独立复算」**其探针读数）。
4. 该增量**触 `fp_inputs()`**（`src/WpfGfx.Linux.Native/src/**` 的 `*.c` 在覆盖面内）⇒ 流程上必须排在采样前，并同趟过 `[42] --fp-manifest --expect`。
5. **代价如实**：**不是一次一跳** —— 簇大小本件未定；每一簇要"创建＋收尾对端＋计数＋镜像"四件套，且**必须先解 `FSFMTRBL`／`FSFMTR` 出参布局**（否则把 `-10000` 换成越界写）。

### 5.2 判据草案（≥3 条可证伪 ＋ **反极性**）

| # | 判据（可证伪的单行式） | **反极性（必红腿）** |
|---|---|---|
| **D1** | **异常面归零**：`grep -c 'did not complete formatting operation' <ev>/app_g1.log` **＝ 0**（今天 427） | 人为在 native 里把「认不出来」改成 `rc=0` 但**出参一字不写** ⇒ `[FS_PAGE_GAP] out=WRITTEN bytes=0 cParas=0` ⇒ **必红**（假成功） |
| **D2** | **拒绝面归零且语义正确**：`grep -c 'reason=unclaimable-para'` ＝ 0 **∧** `grep -c 'reason=unclaimable-subtrack'` ＝ 0（今天 53／370）；且保留的 `reason=ok` 行里 `out=WRITTEN ∧ bytes>0 ∧ cParas>0` | 为凑 `rc=0` 写**常量** `cParas`（如 1）⇒ 会走 `ContainerParaClient` 的**叶子分支**、**静默丢整棵嵌套内容** ⇒ 必须**必红**（`P8` 恒绿陷阱；做法：D2 加一条"`true_cParas` 必须等于窗内枚举真值"） |
| **D3** | **帧面：内容区必须有位移**：`compare -metric AE boot.png k24.png` 的**差异必须落在内容区（x>240）**；即 `bbox(diff) ⊄ [28,240]×[166,555]`。今天 **bbox ＝ `(28,169,240,561)` ⇒ 全部在 ListBox 区 ⇒ 红** | 只让左栏 ListBox 变（今天就是这样）⇒ **必红**；等价反腿：把 `k23==k24`（`AE=0`）当绿 ⇒ **必红** |
| **D4** | **帧面：目标页具名内容锚必须出现**（承 `N1`／`N4` 族）：`k=24` 帧里 `GhostWhite/Beige/DarkGreen/LightGoldenrodYellow` 各 `≥200px`（今天全 **0**），**或** `y∈[40,86] ∧ x∈[258,790]` 的暗像素 `>0`（今天 **0**） | 只有那块 416×312 的占位图（`eq=129792/129792` 命中 `under_construction.gif`）⇒ **必红**；**严禁**把「占位图在场」当"内容已画" |

**附加（**先做的判别实验**，最便宜，用来把"（1）层断"与"呈现面冻结"分开）**：
- 现成反序/异页腿：`clicks=[23,24]`（反序）**或**先点一个**非 PTS 页**（如 `Button`／`Border`），看内容区是否出现像素变化。
  - 若**出现** ⇒ 内容面板**能**重绘 ⇒ 唯一阻塞＝（1）层 ⇒ 直接做 §5.1。
  - 若**不出现** ⇒ 另有一处**呈现面**阻塞（今天的读数**不能**排除它，见 `NOINFO-3`）。
- 该实验**不改产品件、不改判据件**，只是腿的点击序参数（`session_inner.sh` 的 `clicks=` 现取为 `[24,23]`）。

### 5.3 「合法终点」（另一选项，**不推荐**）

**合法终点 ＝ 判「本增量在现写域内不可做」**并具名前置：`PRECOND-NATIVE-OWNS-A-PARAGRAPH-MODEL`（`T-A21` §5.2 已立）＋ `PRECOND-WINDOW-SEPARATION`。
⇒ 若队长选择**不**动 native，则须**同时**接受：① 两页**永远**是空态占位（`N3`／`N4` 永远红）；② 相位**不可翻**（`T-A23` §5 已判 `NO-FLIP`）；③ `[HC-UNHANDLED]` 427 行成为**长期在册**读数。**本件建议选 §5.1**（它有一条明确的可证伪出口：D1／D2 归零 ＋ D3／D4 见像素）。

---

## §6 ⑤ 具名 `NOINFO`（逐条给「消掉需要什么」）

| # | `NOINFO` | 现取依据 | 消掉条件 |
|---|---|---|---|
| `NOINFO-1` | **`asr`／`nav` 机读面** | `grep -rln 'asr'` 于 `tools/`＋`PtsPagesProbe/` **零命中**；`nav=` 同 | 由装置件写者给出 `asr`／`nav` 的**生产者与字段定义**（本件只见到 `navclick.py` 这个文件名） |
| `NOINFO-2` | **`[HC-UNHANDLED]` 的捕获语义**（是否截断/有条数上限/是否常开） | 发射方在**第三方** demo 的 `App.xaml.cs`（`DispatcherUnhandledException` → `LogDiag`，`e.Handled=true`），**不在我方写域** | 读该件捕获分支原文给出上限/开关；或我方加**自己的**计数器 |
| `NOINFO-3` | **「面板像素停在切页前」的机制**（呈现面未重绘 vs 旧视觉仍在树上的**保留式**绘制） | 本件只能证"布局已更新（§3.3）而像素未更新（B1/B4）"；**分不开**下面两种：①新子树**没产出绘制命令**（因（1）层异常中止）；②旧子树的绘制命令**仍在**（即旧内容未从树上摘除） | 需要**一帧绘制命令侧**的读数（`MilChannel`／`MilCommandDispatcher` 计数，或"每子树是否发了 `OnRender`"的插桩）；或 §5.2 的**判别实验**（异页腿） |
| `NOINFO-4` | **`k=23` `AE=0` 的歧义**（"两页同貌" vs "第 23 页没重绘"） | `clicks=[24,23]`（23 是**第二击**）⇒ 无法排除"23 只是没重绘"；本件**未跑**反序腿 | 跑 `clicks=[23,24]` 反序腿（便宜）；本件**只登记** |
| `NOINFO-5` | **`[FSQSTD] reason=claimed-by-provenance-no-content-model`（2 行）的归属** | 现取原文 `rc=-10000 reason=claimed-by-provenance-no-content-model entry=FsQuerySubtrackDetails … out=UNWRITTEN bytes=0`（恰在 `[NS] loaded FlowDocumentDemo` 前一行）、`[PROVCLAIM] … v=CLAIMED-NO-CONTENT-MODEL` | 由 native 写者说明该分支的**判据语义**（与 `unclaimable-*` 的关系）；本件**只报在场** |
| `NOINFO-6` | **MIL／绘制指令层是否收到命令** | `grep -ioE 'MIL\|GlyphRun\|DrawInstruction\|Skia\|RenderTarget' app_g1.log` ⇒ **零命中**（日志不带渲染层标记） | 需要渲染侧计数（`MilChannel`／`MilCommandDispatcher` 的按命令计数）或 `WPF_LINUX_MIL_LOG` 一类通道日志（本趟**未开**） |
| `NOINFO-7` | **`Fs*` 里与"两页能画"直接相关的最小簇有多大** | 本件只取到运行期面（`unclaimable-para` 53／`unclaimable-subtrack` 370）；"哪几条必经"只能逐次试跑得到 | 补一跳后重跑一趟，读 `unclaimable-*` 的**逐入口名分布变化** |
| `NOINFO-8` | **无 WM 腿的"在册口径"归属** | 该腿用**私有补丁副本**（runner `sha16=4056e97b2e591a88` ≠ 在册 `330a90f1f0ac28e4`）⇒ 本件只把它当**装置差**对照（§2.4） | 由装置件写者正式落成 runner 的一支（**本任务不改装置件**） |

---

## §7 边界 · 纪律 · 自证

1. **写域**：**唯一**新增件 ＝ 本载体。现取 `git status --porcelain`（**两项均先于本件**，全属他人）：`?? build/MilBridge/tasks-tail2/T-A24.md`、`?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log`。
2. **只读**：本件命令为 `sha256sum`／`nm`／`wc`／`grep`／`sed`／`awk`／`head`／`cmp`／`compare`／`ls`／`git log`／`git status` ＋ **纯读** Python（只解 PNG/GIF 像素）＋ 对第三方 demo 源（`~/hc-linux/src/Shared/HandyControlDemo_Shared/**`）的**只读** `grep`／`sed`／`cat`（**未写、未运行**）。**零构建、零跑腿、零显示位、零整趟门禁、零 `git` 写。**
3. **不引他人读数当证据**：`T-A23`／`T-A21` 只在**§0/§5 的理由**里作**对照引用**并逐处标「未独立复算」；本件所有数值（帧像素、`AE`、`grep -c`、`[GEO]` 原文、`sha16`、`nm`）**均为本席现取**。
4. **跨代／跨装置不可比（纪律 31/32）**：`boot` 与 `k23`/`k24` 是**同趟同代**（同 `app_g1.log`、同 `shim=e09c8d739c179966`），故 §2／§3 的成对比较成立；**无 WM 腿**是**另一装置**（仅作对照，不作结论承重件）。
5. **口径纪律**：`ENFE_TOTAL`（**0**）与 `[HC-UNHANDLED]`（**427**）**各自定义、不互折**；`[GEO]` 是**布局面**、**不是**绘制面；`ns=` 只证"类型加载"、不证"内容画出"。
6. **未做**：未判相位；未动任何判据件/牙；未跑门禁；未实现任何增量（本件**只侦察＋选靶**）。

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-blank-recon.md | sha256sum | cut -c1-16`）= `d3e83d280285433a`

# P1-tail2 · `T-A35` · 色锚缺席归因 ＋ 选靶 —— 现帧画的是什么／三归因（没画·画别色·没到件）／唯一下一增量

> **本件 `T-A35`（只读侦察子代理）交付**。**写域**：**唯一**新建件 ＝ 本载体 `build/MilBridge/P1-tail2-coloranchor-recon.md`。**未改任何仓内文件**（不碰 `src/**`／`build/**`／`build/MilBridge/tools/**`／装置件／`docs/**`／在册与他代证据目录）；**未构建**；**未跑腿、未占显示位**；**未跑整趟 `verify-all`**；**未跑 `static-jaws-check.sh`**；**未改相位**；未 `git add/commit/push`。现取 `git status --porcelain` 恰两项、**均先于本件且属他人**：`?? build/MilBridge/tasks-tail2/T-A35.md`、`?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log`。
> **口径（不是证据）**：`T-A33` 载体（`P1-tail2-backfill-impl-report.md`）／`T-A34` 载体（`P1-tail2-rearm4-recon.md`）／`T-A32` 载体（`P1-tail2-render-recon.md`）**只作对照**，其读数**一条未抄** —— 本件所有读数**现取**（只读 `sha256sum`／`grep -c`／`wc`／`stat` ＋ **纯读** `PIL`/`numpy` 解 PNG ＋ 只读 `grep`/`read` 第三方 demo 源）。队长裁定二十／二十一／三十五／三十六**只作口径旁引**，读数不引。
> **行号纪律**：本件行号**仅本次有效**；引件一律给**内容锚**。
> **代际（现取）**：`src/WpfGfx.Linux.Native/bin/libwpfwin32.so` ＝ **`04f6d354b0a71888`**｜`build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` ＝ **`1757d610a687777c`**（＝ `T-A33`／`T-A34` 同代，**本席未换代**）。
> **被侦察现场**：**仓内在册**证据目录 `build/MilBridge/tests/PtsPagesProbe/evidence-tail2d/`（`T-A34` 落；本席**只读**复算，**未覆盖、未新增样本**）＋ **仓外只读**第三方 demo 源 `/home/links-dev/hc-linux/src/Shared/HandyControlDemo_Shared/**`。

---

## §0 结论速览（自包含）

1. **① 画面身份复核 ⇒ 现帧是「点击后的 `FlowDocumentDemo` 页」，不是占位、不是别页**（三条独立证据，§2）：运行期 `ns=HandyControlDemo.UserControl.FlowDocumentDemo` ＋ `[NS] loaded …FlowDocumentDemo`；**帧像素自证** —— 该页**自有页签**的两条 CJK 文字带（`x487..565`＝6 字／`x663..729`＝5 字）与**点击后** `[GEO]` 的页签（`scr=440,82`／`611,82` `wh=165x27`，中心 `522`／`693`）吻合，而与 **`boot` 态**页签（`320,82`／`492,82`／`663,82`，中心 `402`／`574`／`745`）**不符**；占位棕族 `121477→0`。
2. **帧内容区既非空、也非占位**：出现**该页自己的文字带**（`k24`：`x303..747`、`y147..258`、9 行、行距≈14.5px、末行仅 `x304..403`＝100px；`k23`：`x319..729`/`y180..199` ＋ `x319..525`/`y205..224`）——**两页彼此不同**（位置/行数/宽度全不同）⇒ 是**排版出的、页专属的**文本，不是同源残留（§2.4）。
3. **② 四色锚缺席归因 ＝「根本没到该控件」**（既非"没画整页"，也非"画了别的色"）：XAML 现取，四具名色**无一例外**只出现在 **PTS 附属对象** `<Figure>`/`<Floater>` 之内（`GhostWhite`＝`Figure`/`Floater` 的 `Background`；`Beige`＋`DarkGreen`＝`Figure` 内 `Paragraph` 的 `Background`/`Foreground`；`LightGoldenrodYellow`＝`Floater` 内 `Table` 的 `TableRow` 的 `Background`）；而 native 回填面**每一条** `[FS_TLB]` 都自报 **`attached-objects(none)`（6104/6104）**，全日志 `Figure`／`Floater` 命中 **0**；帧上**无**任何近似族（`beige~0`／`yellow~0`／`green 0`／`near-GhostWhite` 仅 44px 且落点非块状）（§3）。
4. **③ 唯一选靶 ＝ native 侧「PTS 附属对象（`Figure`/`Floater`）台账 ＋ 查询期回填」**（＝ `T-A33` `NATIVE-QUERY-PHASE-TEXT-LINE-BACKFILL` 的**同族延伸**，`T-A32` 路 (丙) 的后继）⇒ 让承载四色的 `Figure`/`Floater` 块**落到布局并绘出**；判据 4 条可证伪 ＋ 反极性见 §4。**不换靶/不换页**（靶页正确且有页签像素自证）；**非合法终点**（台账侧已有真值，前沿是"接线缺失"）。
5. **④ 具名 `NOINFO` 7 条**（§5），其中 `NOINFO-BLUE-BLOCK-IDENTITY`（蓝块的控件归属）、`NOINFO-CONTENT-BAND-IDENTITY`（文字带的精确身份）与 `NOINFO-ATTACHED-ABSENT-CAUSE`（附属对象未落是"本侧无此概念"还是"页面未完成格式化"）是本轮新读出的三处边界。

---

## §1 证据 · 装置 · 指纹（现取）

| 件（本席现取 `sha16`／字节） | 值 | 备注 |
|---|---|---|
| `evidence-tail2d/app_g1.log` | **`7d4afe71281ac17d`**／`8972955` B | 主证据（一趟腿的装置日志） |
| `evidence-tail2d/leg_24.env` | **`cda66d810fd8838a`** | `k=24`：`ns=…FlowDocumentDemo colors=654 ae=219340` |
| `evidence-tail2d/leg_23.env` | **`444087f41699a229`** | `k=23`：`ns=…RichTextBoxDemo colors=636 ae=125234` |
| `evidence-tail2d/guard-degraded.txt` | **`92895aa671426786`** | 判词全文（本席只读引用，§3.4） |
| `evidence-tail2d/shots/g1/boot.png` | **`b21eb530afd3c66c`**／`190413` | 首屏 |
| `…/k23.png` | **`10d0b9d54e649c10`**／`96957` | `RichTextBoxDemo` |
| `…/k24.png` | **`fa7df9222ebb199f`**／`130624` | `FlowDocumentDemo` |
| `…/last.png` | **`10d0b9d54e649c10`** | 与 `k23.png` 同值（装配不变量：末帧＝第二击帧） |

**装置（现取 `session.txt`／`device.txt`）**：`clicks=[24,23]`（先 24 后 23）；`display=:235`（`DISPLAY_LEASE=official-caller-owned`，`X_UP=yes`）；`shim_sha16=04f6d354b0a71888 pf_sha16=1757d610a687777c`；`runner_sha16=330a90f1f0ac28e4 session_sha16=f1a582d9ea9788c9`；`APP_RC=143`（`SIGTERM`，仪器收的）；`FIVE_STABLE_G1=YES`。
**方法边界**：本席**未**重跑腿、**未**占显示位、**未**改判据件；帧面读数是**只读 PNG 解码**（`PIL`＋`numpy`）；对 `FlowDocumentDemo.xaml`／`RichTextBoxDemo.xaml`（仓外）**只读** `read`／`grep`。
**探针闸（裁定三十六 (c)）**：本件帧面均取自 **`WPF_PTS_DRIVE_PROBE` 缺省＝开**的那一趟（`T-A34` 现场）⇒ **同闸状态内可比**；跨闸状态**不**可比（见 `NOINFO-7`）。

---

## §2 ① 画面身份复核（像素／色／几何／`[GEO]`／`[NS]`）

### 2.1 页身份（运行期，现取）

| # | 现取证据 | 它证明什么 |
|---|---|---|
| `A1` | `leg_24.env`：`ns=HandyControlDemo.UserControl.FlowDocumentDemo`（`k=24`） | 应用自报页身份 **＝ 目标页** |
| `A2` | `[NS] loaded HandyControlDemo.UserControl.FlowDocumentDemo … upHits= UP0=FlowDocumentDemo` | 该 `UserControl` **已挂进有呈现源的树** |
| `A3` | `[STATE] … LB(ListBoxDemo sel=23/31)`（尾段）／`session.txt`：`BEFORE item=24 … expect=FlowDocumentDemo`／`AFTER item=24 … expect_hit=yes` | 点击**打到了**目标项 |

### 2.2 帧面几何（本席现取，只读 PNG）

**画布**：`1280x1024x24`。非黑窗口恰 `x∈[0,799] ∧ y∈[0,599]`（`480000` px）；域外黑 `830720` px（三个帧**逐帧相同**）。

| 量（现取 `Counter` 精确计数） | `boot.png` | `k23.png` | `k24.png` |
|---|---|---|---|
| `(255,255,255)` 白 | `203900` | `303433` | **`354350`** |
| `(0,0,0)` 黑 | `830720` | `830720` | `830720` |
| `(238,238,238)` 灰 | `108382` | `84113` | `39130` |
| **`(50,108,243)` `#326CF3` 蓝** | `156` | **`13511`** | **`14372`** |
| `(47,102,229)` `#2F66E5` 深蓝 | `0` | `3341` | `3016` |
| 不同色数 `ncolors` | `386` | `636` | `654` |

**内容区（`x>240`）现取结构（`k24`）**：

| 带 | 现取几何 | 像素身份 | 与上游对照 |
|---|---|---|---|
| 蓝块 | `y49..81`、`x268..782`（≈514×33） | 纯 `#326CF3`；其内**有 3 簇白字/图标**（`x283..296`／`x509..541`／`x754..770`，`y58..72`） | 同带 `[GEO]` 恰两件：`Button#- scr=274,52 wh=29x25`、`ToggleButton#- scr=748,51 wh=27x27` ⇒ **左/右两簇对得上控件；中簇（`x509..541`）无 `[GEO]` 对件** ⇒ 见 `NOINFO-BLUE-BLOCK-IDENTITY` |
| **页签文字带** | `y91..101`：`x487..565`（78px≈6 字）、`x663..729`（66px≈5 字） | CJK 文字 | **点击后** `[GEO]`：`TabItem hdr=流文档单页视图 scr=440,82 wh=165x27`（中心 `522`）、`hdr=流文档查看器 scr=611,82`（中心 `693`）、`hdr=流文档滚动视图 scr=268,82 … sel=True`。帧观 `526`／`696` **吻合 `522`／`693`**；**`boot` 态** `[GEO]` 页签中心为 `402`／`574`／`745` ⇒ **不吻合** |
| 蓝短条 | `y109..110`、`x268..439`（宽 `172`≈页签1 宽 `165`） | `#326CF3` | 与页签1 同宽同列（角色未定，见 `NOINFO-BLUE-BLOCK-IDENTITY`） |
| **文字带×9** | `x303..747`、`y147..258`，行距≈`14.5`px；行高 `11~12`px；**末行仅 `x304..403`（100px）** | 全**灰阶**（`white 27103`／`(33,33,33) 3272`／`(102,102,102) 833`…，`grayscale=1.00`） | 逐行读法见 §2.4 |

**`k23`（`RichTextBoxDemo`）对照**：蓝块 `y107..139`、`x283..766`（≈484×33）；文字带两处 `x319..729`/`y180..199` 与 `x319..525`/`y205..224`。⇒ **两页各带位置、行数、宽度均不同**。

### 2.3 占位缺席（现取，逐像素）

以"占位棕色族"（`180≤r≤220 ∧ 125≤g≤170 ∧ 105≤b≤145`，与 `T-A34` **同族**；本席独立复算）计：

```
OLD k24 占位像素=121477   OLD boot=121477     （在册 evidence/，只读对照）
NEW k24 占位像素=0        NEW boot=121477     （evidence-tail2d/）
```

并取 `T-A32` 登记的占位 `bbox=(317,137)-(732,448)`（416×312）在 **新帧** 内取样：**只有白与灰阶**（`255,255,255`／`33,33,33`／`102,102,102`／…），**无**占位棕族。⇒ **占位图在新帧 `k24`/`k23` 上消失，`boot` 仍在**。

### 2.4 判（含"是不是应有内容"的成对读法）

- **是 `FlowDocumentDemo` 页**（`A1`–`A3` ＋ §2.2 页签像素自证 ⇒ **不是别页、不是占位**）。
- **页内容"有像素"但不是空的**：内容区出现**页专属文字带**（`k24` 9 行 vs `k23` 2 带，几何全不同 ⇒ **非同一残留**）。
- **⚠️ 但不得读成"该页内容真绘出"**：文字带**退化** —— 以 `k24` 三行现算，`≥4px` 空隙仅 **0–5 处/445px 行**、`lum<100` 列覆盖率 **85–93%**、且文档默认字体**未解析**（§3.4 `[FONT_FALLBACK]`：`requested=GLOBAL USER INTERFACE fallback=yes resolved=none`）。⇒ 该文字带的**精确身份**记 `NOINFO-CONTENT-BAND-IDENTITY`，**本件不据此单独判绿**（承裁定二十一 ②／三十六 (c)③：帧面绿永不单独支撑排版结论）。
- 与 `T-A34` 一致：`I-1..I-4`（帧身份∉空态集、两页帧分离、占位消失、内容区有像素）**成立但必要非充分**；`I-5`（色锚）**仍 ✘**。

---

## §3 ② 四色锚现取归因（**没画 / 画别色 / 没到件**）

### 3.1 上游 XAML 现取（仓外只读，逐行）

`/home/links-dev/hc-linux/src/Shared/HandyControlDemo_Shared/UserControl/Styles/FlowDocumentDemo.xaml`（本席现取，只读）：

| 具名色 | 出现处（现取原文锚） | 所在块 |
|---|---|---|
| `GhostWhite` | `<Figure Width="140" Height="50" Background="GhostWhite" …>`（第 1 段内）／第 3 段内 `<Figure … Background="GhostWhite" …>`／`<Floater Background="GhostWhite" Width="285" …>` | **Figure（×2）＋ Floater（×1）＝ 全是 PTS 附属对象** |
| `Beige` | 上述 `Figure` 内 `<Paragraph FontStyle="Italic" … Background="Beige" Foreground="DarkGreen">` | **Figure 内 Paragraph** |
| `DarkGreen` | 同上 `<Paragraph … Foreground="DarkGreen">` | **Figure 内 Paragraph** |
| `LightGoldenrodYellow` | `Floater` 内 `<Table>` 的两个 `<TableRow Background="LightGoldenrodYellow" FontSize="12">` | **Floater 内 Table 的 TableRow** |

⇒ **四具名色一无所例外，全部落在 `<Figure>`／`<Floater>`（＝ PTS 附属对象）之内。**（`RichTextBoxDemo.xaml` 与此相反：无任何具名色，只有 `Margin/Width/Height` 与三段 `Paragraph`。）

### 3.2 帧面色系现取（`PIL` 只读，三帧成对）

| 面 | `boot` | `k23` | `k24` |
|---|---|---|---|
| 精确 `GhostWhite(248,248,255)` | `0` | `0` | `0` |
| 精确 `Beige(245,245,220)` | `0` | `0` | `0` |
| 精确 `DarkGreen(0,100,0)` | `0` | `0` | `0` |
| 精确 `LightGoldenrodYellow(250,250,210)` | `0` | `0` | `0` |
| `LightGray(211,211,211)`（**不入锚集**，反标定用） | `44` | `59` | `147` |
| 近似族·beige（`|r-245|<12 ∧ |g-245|<12 ∧ |b-220|<16 ∧ r-b>10`） | `0` | `0` | `0` |
| 近似族·yellow（`r>230 ∧ g>230 ∧ b<225 ∧ r-b>20`） | `0` | `0` | `0` |
| 近似族·green（`g>r+20 ∧ g>b+20`） | `18`（`(84,135,81)` 等，UI 图标） | `0` | `0` |
| 近似族·near-GhostWhite（`|r-248|<6 ∧ |g-248|<6 ∧ 0<b-r<12`） | `7` | `111` | `44`（落点 `x43..540`/`y61..437`，**非块状**；蓝块边/左栏） |

⇒ **不是"画了别的近似色"**（beige/yellow 近似族恒 0；green 仅 `boot` 的 18px UI 图标；near-ghost 的几十像素为抗锯齿边、**不构块**）。

### 3.3 机读面现取（`app_g1.log`）

| 面 | 现取 |
|---|---|
| `[FS_TLB]` 总行 | `7632`（`FsQueryTextDetails 6104` ＋ `FsQueryLineListSingle 1528`） |
| **`[FS_TLB] … NOINFO=…,attached-objects(none)`** | **`6104/6104`（100%）** |
| `[FSQTD]` | `6104`，全 `rc=0 … out=WRITTEN bytes=112` |
| `[FSQLL]` | `1528`，全 `rc=0 … out=WRITTEN bytes=576` |
| `reason=no-text-line-model` | **`0`**（保持归零） |
| `[HC-UNHANDLED]` | **`1`**（`… did not complete formatting operation … '-10000'`） |
| `[FS_PAGE_GAP]` | **`1`**：`rc=-10000 reason=drive-handles-released(page-destroyed) entry=FsQueryTrackParaList …` |
| `reason=` 分布（全日志） | `ok 21384`｜`handle-zero 17`｜`doc-already-driven 3`｜`need-real-format-frame 1`｜`drive-handles-released 1` |
| **`Figure`／`Floater` 字样** | **`0`／`0`**（`grep -ci`） |
| `[FONT_FALLBACK]` | `GLOBAL USER INTERFACE fallback=yes resolved=none`×2｜`GEORGIA … resolved=none`×3｜`ARIAL … resolved=none`×1｜`DEJAVU SANS resolved=ok`×2｜`NOTO SANS CJK JP resolved=ok`×2 |
| `[NS]／[GEO]`（现取） | `[NS] loaded …FlowDocumentDemo`；`[GEO]`（点击后）三页签 `scr=268/440/611,82 wh=165x27` |

### 3.4 判（三归因的逐条排除）

- **不是"没画整页"**：页签两条文字带在帧上、且与点击后 `[GEO]` 坐标吻合；`[FSQTD]`/`[FSQLL]` `rc=0 out=WRITTEN`；文字带页专属（§2.4）。
- **不是"画了别的色"**：§3.2 近似族**全 0/不构块**；帧上没有任何 140×50（`Figure`）或 285 宽（`Floater`）的浅色块。
- **✅ 是"根本没到该控件"** —— 具名到**块**：**承载四色的 `Figure`／`Floater`（PTS 附属对象）未落、未绘**。三条同向：
  1. **出处唯一性**（§3.1）：四色**全部且仅仅**在 `Figure`/`Floater` 内 ⇒ 附属对象不绘 ⇒ 四色必为 0（**可算出的必然**）。
  2. **本侧自报无此物**（§3.3）：`[FS_TLB]` 每条 `attached-objects(none)`；日志 `Figure`/`Floater` 命中 **0** ⇒ 本侧**没有**附属对象这一概念/台账（＝**接线缺失**，非"三源缺失"）。
  3. **帧面实证**：内容区只有流文本带（§2.2），**无**任何附属对象块几何。
- **⚠️ 口径边界**：本件**只证"四色锚的承载块（`Figure`/`Floater`）未到"**；"未到的**原因**归属"（本侧无此概念 vs 页面未完成格式化）记 `NOINFO-ATTACHED-ABSENT-CAUSE`（旁证：全日志**唯一** 1 条 `[HC-UNHANDLED] … did not complete formatting` 出自 `FsQueryTrackParaList`，且是 `drive-handles-released(page-destroyed)` 的**页销毁**路径）。
- **`PTS_COLORANCHOR` 现取判词（只读引用 `guard-degraded.txt`，本席未跑）**：`PTS_COLORANCHOR=FAIL k=24 … hits=0 expect_min=200 expect_hits=2 baseline=… phase=degraded reason=declared-color-anchor-absent`；`PTS_COLORANCHOR=NOINFO k=23 reason=no-anchor-registered-for-k23`。

---

## §4 ③ 唯一选靶 ＋ 理由 ＋ 判据草案（≥3 条可证伪 ＋ 反极性）

### 4.1 唯一增量（具名）

> **`NATIVE-PTS-ATTACHED-OBJECTS-BACKFILL`**（＝ `T-A33` `NATIVE-QUERY-PHASE-TEXT-LINE-BACKFILL` 的**同族延伸**；`T-A32` 路 (丙) 的后继）：
> 在 `src/WpfGfx.Linux.Native/src/win32_pts.c` 上，为查询期引入 **PTS 附属对象（`Figure`／`Floater`）台账**，并把 `FsQueryTextDetails` 回填行里的 `attached-objects(none)` 换成**具名、可对拍**的真值（附属对象种类/个数/锚点/几何），使 `Figure`（`Background=GhostWhite`、内含 `Beige`＋`DarkGreen` 段）与 `Floater`（`Background=GhostWhite`、内含 `Table` 的 `LightGoldenrodYellow` 行）**落到布局并被下游绘出**。
> **未驱动／认不出身份／未造型 ⇒ 仍拒（出参一字不写）**；`P8`（若涉生成件 ⇒ 改生成器）。**落点**：`win32_pts.c`（`bin/exports.txt` 若随动）。

**理由（逐条，均有 §3 现取证据）**：
1. **出处唯一性**：四具名色**全部且仅仅**在 `Figure`/`Floater` 内（§3.1）⇒ 这是**唯一**能同时解释"四色全 0"与"流文本带/页签都出像素"的落点（§3.4）。
2. **不是"三源缺失"是"接线缺失"**：本侧逐条自报 `attached-objects(none)`（`6104/6104`），日志 `Figure`/`Floater` 命中 `0`（§3.3）⇒ 有真值可信（`T-A33` 回填面已 `rc=0 out=WRITTEN`），缺的是**附属对象这一段接线**。
3. **上游已通**：段落模型 `[FSQSTD]`/`[FSQSPL]` `rc=0`；行台账 `[FORMATLINE-LINE] 42` 行；回填面 `[FSQTD] 6104`／`[FSQLL] 1528` 全 `rc=0`（§3.3）；`no-text-line-model 0`。⇒ 前沿**只在附属对象**。
4. **帧面指向明确**：内容区现只有"退化文字带"（`x303..747`/`y147..258`），**无**任何块状附属几何；四色精确 0、近似族 0（§3.2）⇒ 靶**不是**"再修文本"，而是"补附属对象"。
5. **触 `fp_inputs()`**：`src/WpfGfx.Linux.Native/src/**` 在覆盖面内 ⇒ 流程上须排在采样前并同趟过 `[42] --fp-manifest --expect`。
6. **代价如实**：**不是确定的一跳** —— 与 `T-A32` `NOINFO-HOSTLINE-NATIVE-BACKFILL-SEMANTICS`／`NOINFO-LEDGER-PFSLINE-DEREF` 同族，本增量**至少要先答两问**：① 真机字段映射（附属对象在 `FSTEXTDETAILS`/行盒里如何表示）；② 附属对象的**几何来源**（`HorizontalAnchor`/`HorizontalOffset`/`VerticalOffset`/`Width`/`Height`／`WrapDirection`）从哪个入站面取（现盘 `[FSQSTD-SRC] NOINFO=fsupdinf(no-source),fsrc(declared-geometry)` 显示几何面本身仍是 `declared`）。

### 4.2 判据草案（4 条可证伪 ＋ 反极性必红腿）

| # | 判据（可证伪的单行式） | **反极性（必红腿）** |
|---|---|---|
| **D1 台账实名化／零假值** | `[FS_TLB]` 的 **`attached-objects(none)` 归零**或改为**具名真值**（如 `attached-objects=figure=2,floater=1`，种类/个数来自入参枚举，非常量）；**未写出参 ≠ 写 0**；拒绝路径出参**一字不写**（承 `out=UNWRITTEN bytes=0`）。 | 为让读数好看写**常量** `attached-objects=2`（或把 `none` 直接删掉）⇒ 消费者当"有附属对象"⇒ **必红**（`P8` 恒绿陷阱）。 |
| **D2 色锚转 `PASS`（可证伪）** | `k=24` 帧四具名色**各 `≥200px`**（或 `hits≥2`）⇒ `PTS_COLORANCHOR=PASS`；**且** `baseline(boot.png)` 四色**仍全 0**（活锚）；`LightGray` **不入集**。 | 只令某**近似灰/白**超阈（如 `(249,249,249)`）⇒ **必红**；用 `k=24` 的锚**推广**到 `k=23` ⇒ **必红**。 |
| **D3 块状几何落位（可证伪）** | `k=24` 帧上出现 `≥1` 个**块状**元素（`Figure 140x50` 或 `Floater` 285 宽），其像素**∈ 具名色**；且 `[GEO]` 增件或坐标系落 `x∈[268,790]`；`AE(boot,k24)` 的差异分量落在**内容区**（不是仅蓝块/页签位移）。 | 只挪动蓝块或页签 ⇒ **必红**；把"内容区像素变多"（`colors 383→654`）当绿 ⇒ **必红**。 |
| **D4 失败必留痕 ＋ 计数恰涨 1** | 附属对象**认不出/未落**时**必**打印具名行（`entry=` ＋ `reason=` ＋ `gap` **恰 +1**），与"真 0 次"**可分**。 | 静默 stub（返非 0 零痕迹）⇒ 与"真 0 次调用"不可分 ⇒ **必红**。 |

**最便宜的反极性腿（本件只登记、不跑）**：撤掉 / 置空附属对象回填（或 `WPF_PTS_DRIVE_PROBE=0` 那趟）⇒ **四色必须回 0**，且 `[HC-UNHANDLED]` **不得下降**。

### 4.3 另两个选项（**不推荐**，如实并列）

- **换靶／换页**：**不** —— 靶页身份**正确**且有**页签像素自证**（§2.2），两页 XAML 自身无占位（`T-A32` 同判，本席 §2.3 复算）⇒ 换页无据。
- **合法终点**：**不** —— 四色锚的**出处唯一**（§3.1）、且本侧**自报**缺此物（§3.3）⇒ 前沿是**接线缺失**而非"不可做"。

---

## §5 ④ 具名 `NOINFO`（逐条给"消掉需要什么"）

| # | `NOINFO` | 现取依据 | 消掉条件 |
|---|---|---|---|
| `NOINFO-BLUE-BLOCK-IDENTITY` | 内容区**蓝块**（`k24` `y49..81 x268..782`≈514×33；`k23` `y107..139 x283..766`≈484×33；纯 `#326CF3`，含 3 簇白字/图标）的**控件归属** | 同带 `[GEO]` 仅 `Button#-(274,52)`／`ToggleButton#-(748,51)` 两件 ⇒ 左/右两簇有对件，**中簇 `x509..541` 无对件**；本席**只测** | `[GEO]` 增件（把中簇点名）或渲染/命令侧读数；本件**未开**渲染侧通道 |
| `NOINFO-CONTENT-BAND-IDENTITY` | 内容区**文字带**（`k24` `x303..747`,`y147..258`,9 行；末行 `100px`）的**精确身份**（是否 `FlowDocument` 首段 8 行） | 带为**页专属**（`k24` 9 行 vs `k23` 2 带，几何全不同）⇒ **是排版出的文本**；但**退化**（`≥4px` 空隙 `0–5`/445px；`lum<100` 列覆盖 `85–93%`），且默认字体 `GLOBAL USER INTERFACE resolved=none` ⇒ **不**读成"正常绘出" | 文本侧通道读数；或字体解析修复后重取；本件**只测** |
| `NOINFO-ATTACHED-ABSENT-CAUSE` | 附属对象**未落的归因归属**（"本侧无此概念" vs "页面未完成格式化"） | 现取 `attached-objects(none) 6104/6104` ＋ `Figure/Floater 0`；**另有**全日志唯一 1 条 `[HC-UNHANDLED] … did not complete formatting`（`FsQueryTrackParaList`，`drive-handles-released(page-destroyed)`＝**页销毁**路径）⇒ **两因并存，本席分不开** | 实现后自证；或驱动/命令侧读数（同 `T-A32` `NOINFO-CONTENT-PANEL-FREEZE` 族） |
| `NOINFO-DOC-BODY-PARTIAL` | 两页**文档体为何只出少量行**（`k24` 首段 ≈9 带；`k23` 仅 2 带），其余段/段落未见带 | 现取内容区 `y110..595` 逐行扫描：`k24` 带止于 `y258`，其后至 `y594` 无带 | 同上（附属对象/格式化完成后重取） |
| `NOINFO-K23-ANCHOR` | `k=23` 色锚 | 守卫现取 `PTS_COLORANCHOR=NOINFO k=23 reason=no-anchor-registered-for-k23`（`RichTextBoxDemo.xaml` **无具名色**） | 为 `k=23` 另立**活锚**（**严禁**用 `k=24` 的锚推广） |
| `NOINFO-FRAME-DETERMINISM` | 帧面确定性 `PRECOND-FRAME-DETERMINISM` | 本席只取 `evidence-tail2d` 单一证据目录（一主样本）；**未**取同装置内变体分布 | 按族级纪律取 ≥20 独立样本、逐趟记代际指纹、批内代际守卫 |
| `NOINFO-PROBE-GATE-OFF` | **探针闸关闭**状态下的帧面 | 本件帧面均取自 `WPF_PTS_DRIVE_PROBE` **缺省＝开**的一趟（裁定三十六 (c)②） | 以 `WPF_PTS_DRIVE_PROBE=0` 跑一趟反极性腿取帧面（**本任务未要求**） |

---

## §6 可复跑单行命令原文（本席实跑，现取）

```sh
cd /home/links-dev/netTest/GitProj/WPFOnLinux
D=build/MilBridge/tests/PtsPagesProbe/evidence-tail2d

# 代际 / 证据指纹
sha256sum src/WpfGfx.Linux.Native/bin/libwpfwin32.so | cut -c1-16            # ⇒ 04f6d354b0a71888
sha256sum build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll | cut -c1-16  # ⇒ 1757d610a687777c
sha256sum $D/app_g1.log $D/leg_23.env $D/leg_24.env $D/guard-degraded.txt | cut -c1-16
sha256sum $D/shots/g1/{boot,k23,k24}.png | cut -c1-16

# 机读面（现取）
grep -c '\[FS_TLB\]' $D/app_g1.log                                    # ⇒ 7632
grep -o 'attached-objects([^)]*)' $D/app_g1.log | sort | uniq -c      # ⇒ 6104 attached-objects(none)
grep -ci 'Figure' $D/app_g1.log; grep -ci 'Floater' $D/app_g1.log     # ⇒ 0 / 0
grep -c 'no-text-line-model' $D/app_g1.log                            # ⇒ 0
grep -c '\[HC-UNHANDLED\]' $D/app_g1.log                              # ⇒ 1
grep -n 'FS_PAGE_GAP' $D/app_g1.log                                   # ⇒ 1 行（FsQueryTrackParaList）
grep 'FONT_FALLBACK' $D/app_g1.log | sort | uniq -c
grep -n 'TabItem#- .*hdr=流' $D/app_g1.log | sed -n '4,6p;10,12p'     # 点击后页签 scr=268/440/611,82

# 帧面（纯读 PNG）
python3 - <<'PY'
from PIL import Image; import numpy as np, collections
D="build/MilBridge/tests/PtsPagesProbe/evidence-tail2d/shots/g1"
anch={'GhostWhite':(248,248,255),'Beige':(245,245,220),'DarkGreen':(0,100,0),'LightGoldenrodYellow':(250,250,210)}
for f in ('boot.png','k23.png','k24.png'):
    c=collections.Counter(map(tuple,Image.open(f"{D}/{f}").convert("RGB").getdata()))
    print(f, {k:c.get(v,0) for k,v in anch.items()}, 'blue250,108,243=',c.get((50,108,243),0),
          'white=',c.get((255,255,255),0), 'ncolors=',len(c))
PY

# 四色出处（仓外只读）
grep -n 'GhostWhite\|Beige\|DarkGreen\|LightGoldenrodYellow' \
  /home/links-dev/hc-linux/src/Shared/HandyControlDemo_Shared/UserControl/Styles/FlowDocumentDemo.xaml
# ⇒ 命中全在 <Figure>(:21,:85,:22,:86) 与 <Floater>(:26,:38,:54) 内
```

---

## §7 边界 · 纪律 · 主动披露

1. **写域**：**唯一**新增件 ＝ 本载体（现取 `ls` 交付前**不存在**：`没有那个文件或目录`）。**未覆盖**在册 `evidence/` 与他代 `evidence-tail2*/`；**未碰** `src/**`／`build/shape`／`build/close-wave.sh`／`build/MilBridge/tools/**`／`docs/**`。**未** `git add/commit/push`。
2. **只读**：本件命令为 `sha256sum`／`grep`／`sed`／`head`／`tail`／`wc`／`stat`／`ls`／`git status` ＋ **纯读** `python3`（只解 PNG 像素）＋ 对第三方 demo 源（`/home/links-dev/hc-linux/…`）与在册证据目录的**只读** `read`／`grep`。**零构建、零跑腿、零显示位、零整趟门禁、零 `static-jaws-check.sh`、零 `git` 写、零相位改。**
3. **不引他人读数当证据**：`T-A32`／`T-A33`／`T-A34` 只在 §0／§3.4／§4 的理由里作**对照引用**（并逐处标注），本件所有数值（`sha16`／`grep -c`／帧像素 `Counter`／`[GEO]`／`[FS_TLB]` 原文）**均为本席现取**。占位 bbox `(317,137)-(732,448)` 是**引 `T-A32` 的坐标**（本席取其**框内取样**作复算）。
4. **跨代／跨装置不可比（纪律 31/32）**：本件"旧"（在册 `evidence/`）与"新"（`evidence-tail2d/`）是**两代 `.so` ＋ 两趟时刻** ⇒ 只报**结果**（占位 `121477→0` 等），**不做减法**承重。
5. **口径纪律**：`[GEO]`／`[NS]` 是**布局/加载面**，**不是**绘制面；`ns=` 只证"类型已加载"；`[FSQTD] rc=0`／`rc=0 reason=ok` **≠** 内容已画；`[FS_TLB]` 的 `attached-objects(none)` 是**本侧自报**（写者自证，作**指向**不作**裁定**）。
6. **未做（防被读宽）**：未实现任何增量（本件**只侦察＋归因＋选靶**）；未改相位；未动判据件/牙；未新增任何 `D-G<digits>` 登记编号；**未**跑反极性腿；**未**新增/覆盖任何证据目录。
7. **装置未就绪的重试披露**：本件**未跑腿** ⇒ 无重试；一切读数取自 `T-A34` 已落地的**在册**现场（`evidence-tail2d/`），并由本席**逐格复算**。

---

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-coloranchor-recon.md | sha256sum | cut -c1-16`）= fb045f765730461e

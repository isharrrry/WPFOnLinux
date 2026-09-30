# P1-tail2 · `T-A32` · 链驱动后帧面仍空 —— 渲染/绘制路径侦察 ＋ 页身份复核（**只读侦察件**）

> **本件 `T-A32`（只读侦察子代理）交付。写域**：**唯一**新建件 ＝ 本载体 `build/MilBridge/P1-tail2-render-recon.md`。
> **未改任何仓内文件**（不碰 `src/**`、`build/MilBridge/tools/**`、装置件、在册证据目录、`docs/**`）；**未构建**；**未跑整趟 `verify-all`**；**未跑 `static-jaws-check.sh`**；**未跑腿、未占显示位**；未 `git add/commit/push`。
> **口径**：一切读数**本席现取**（`sha256sum`／`grep -c`／`wc`／`cmp`／`python3` 只读 PNG/GIF）；**未抄任何既有报告的读数**（引用他人件处逐条标「未独立复算」）。**行号一律「仅本次有效」**，引件给内容锚。
> **代际（现取）**：`HEAD` ＝ `0ffa69c0355ee92263c53d5d41924fd21e890a7d`（＝ `T-A31` 落地笔）｜`src/WpfGfx.Linux.Native/src/win32_pts.c` ＝ **`d0d5f43f7a09f2b0`**｜`src/WpfGfx.Linux.Native/bin/libwpfwin32.so` ＝ **`ac002caa324a496f`**。
> **被侦察现场（`T-A31` 落，**仓外**，本席只读）**：`~/tA31-work/legs-newdef/`（`WPF_PTS_FL_DRIVE` **缺省开**之一趟腿，`2026-09-30 16:15`；同批 `legs-{newdef2..4,olddef×3,polar0×2}` 另存）。

---

## §0 结论速览（自包含）

1. **① 页身份复核 ⇒ 靶正确（不是"靶错"）**：`k=24` ＝ `HandyControlDemo.UserControl.FlowDocumentDemo`、`k=23` ＝ `…RichTextBoxDemo`（运行期 `[NS] loaded` ＋ `[GEO]` 页签双证，§2）。**这两页的 XAML 自身都不含「敬请期待」占位** —— 全树 `grep -rn UnderConstruction --include=*.xaml` **仅一处**：`PracticalDemo.xaml:9`（首屏）；`UnderConstruction.xaml`（`GifImage` 400×300 ＋ `ComingSoon` 文本）**只被 `PracticalDemo` 用**。⇒ **§① 的"若靶页本就空态"不成立 ⇒ 不换页/不换腿**。
2. **② 帧面身份（像素级，本席自算）**：`k24` 帧内容区**没有目标页任何像素**；帧上恰有一块 `129792` 像素、`bbox=(317,137,732,448)`（＝ 416×312）的块，**逐像素 ∈ `under_construction.gif` 调色板** ⇒ 帧画的是**首屏 `PracticalDemo` 的空态占位**；目标页具名色锚 `GhostWhite/Beige/DarkGreen/LightGoldenrodYellow` **各 0 px**；`[GEO]` 里 `k=24` 自有页签应在的带（`y∈[40,86] ∧ x∈[258,790]`）**暗像素 6**（纯属窗口边）⇒ 页签**没画**。`k23 ≡ k24`（逐字节同 `sha16`）、与 `T-A24` 在册帧 **`cmp` IDENTICAL** ⇒ **本趟帧面零位移**。
3. **③ 第一处断点 ＝ native 侧「回查」未接线**（唯一断点，逐层证据见 §3）：`FsQueryTextDetails` 恒拒 **`reason=no-text-line-model`（105 行，`rc=-10000 out=UNWRITTEN bytes=0`）** ⇒ 托管 `PtsException(-10000)`（`[HC-UNHANDLED]` **109**，单一型）⇒ 布局/校验中止 ⇒ 内容区零绘制。**上游已通**：段落模型 `[FSQSTD]`/`[FSQSPL]` **`rc=0 reason=ok`（702/698）**、行模型 `[FORMATLINE] v=LINES-RECORDED`（7 段）＋ 行记录台账 `[FORMATLINE-LINE]` **42 行**（含 `dcp/dcpLine/ascent/descent/durbbox/pfsline`）；**下游（MIL 命令／渲染通道／DV 几何／`MilChannel`）本趟取不到任何标记（零命中）**，但**因断点在上游，下游本无从谈起**。
4. **④ 唯一选靶 ＝ native「回查」增量**（＝ `T-A27` 设计草案**路 (丙) 的第 3 步**「回查」；前两步 1 驱动／2 台账已由 `T-A28`→`T-A31` 落地）：把本侧行记录台账**回填**进 `FsQueryTextDetails`（出参 `FSTEXTDETAILS`／`fsktdFull`）＋ 三入口 `FsQueryLineList{Single,Composite}`／`FsQueryLineCompositeElementList` 的行盒。**落点**：`src/WpfGfx.Linux.Native/src/win32_pts.c`（＋ `bin/exports.txt` 若随动）。判据 4 条可证伪 ＋ 反极性见 §4.2。**理由**：现取的"断"**唯一**在此层，且台账**已有真值**（不是"三源缺失"，是"接线缺失"）。
5. **⑤ 具名 `NOINFO` 6 条**（§5），其中 `NOINFO-HOSTLINE-NATIVE-BACKFILL-SEMANTICS`（真机字段映射）与 `NOINFO-LEDGER-PFSLINE-DEREF`（台账里 `pfsline` 的真身是 `0xc…` 一类的**小值句柄**、非本例可 deref 的指针）是**本轮新读出的两处边界** —— 正是回查接线必须先答的两问。

---

## §1 证据 · 装置 · 指纹（现取）

| 件（本席现取 `sha16`／行数） | 值 | 备注 |
|---|---|---|
| `~/tA31-work/legs-newdef/app_g1.log` | **`a69d842b61714d89`**（5994 行） | 主证据（一趟腿的装置日志） |
| `…/session.txt` | **`3f37354ac0c6769f`** | 腿/点击序/帧行 · 现取原文见 §1 脚注 |
| `…/leg_24.env` | **`ee1af2fb5918c07d`** | `k=24`：`ns=…FlowDocumentDemo ae=15386` |
| `…/leg_23.env` | **`118280ad06532ae1`** | `k=23`：`ns=…RichTextBoxDemo ae=0` |
| `…/shots/g1/boot.png` | **`b21eb530afd3c66c`** | 190413 B |
| `…/shots/g1/{k23,k24,last}.png` | 三件同值 **`ef3fd6765f18f51b`** | 各 189716 B，三帧**逐字节相同** |

**装置（现取 `session.txt`）**：`clicks=[24,23]`（先 24 后 23）；`display=:231`（`DISPLAY_LEASE=official-caller-owned`，`x_up=yes`）；`shim_sha16=ac002caa324a496f pf_sha16=1757d610a687777c`；`runner_sha16=330a90f1f0ac28e4 session_sha16=f1a582d9ea9788c9`；`LEGS_RUNNER=PASS requested=2 obtained=2 refused=0`；`APP_RC=143`（`SIGTERM`，仪器收的）；`HEAVYSLOT=RELEASED`。
**五件（现取 `five_pre_g1.txt`）**：`libwpfwin32.so=ac002caa324a496f`｜`wpfgfx_cor3.so=941e69902d82ef02`｜`PresentationCore.dll=e47c4b4521c54cb2`｜`PresentationFramework.dll=1757d610a687777c`｜`WindowsBase.dll=3886f61b0251140e`。`five_post_g1.txt` 同值 ⇒ 跑中无件漂移。
**方法边界**：本席**未**重跑腿、**未**占显示位；日志/`env` 面读数是**文件内容**（`sha16` 已给），帧面读数是**只读 PNG 解码**（`PIL`，纯读）；第三方 demo 源（`~/hc-linux/src/Shared/HandyControlDemo_Shared/**`）**只读** `grep`／`read`，**未写、未运行**。

**标签直方图（本席现取 `grep -oE '^\[[A-Z0-9_-]+\]' app_g1.log | sort | uniq -c`，取前 12）**：
```
927 [GEO]          702 [FSQSTD]       698 [FSQSTD-SRC]   698 [FSQSPL]
652 [QPD]          328 [WINDOW-SPLIT] 325 [FSPARALIST-PARA] 325 [FSPARALIST-FILL]
309 [FSCBK-WORD]   222 [HCIN]         109 [HC-UNHANDLED] 108 [VIS]
107 [FSUPDFSP]     107 [CLRUPD]       105 [FS_PAGE_GAP]    45 [FSCBK-CANARY]
42 [FORMATLINE-LINE]  30 [NMP-TYPE]   12 [TEXTLINE_LSEM]  10 [FORMATLINE]   7 [NS]
```

---

## §2 ① 页身份复核（XAML ＋ 运行期证据）

### 2.1 XAML 侧（现取，第三方 demo 源，**只读**）

| 页 | 件（现取原文） | 是否含「敬请期待」占位 |
|---|---|---|
| `k=24` `FlowDocumentDemo` | `UserControl/Styles/FlowDocumentDemo.xaml` | **否** —— 树为 `hc:TransitioningContentControl` → `TabControl` ＋ 3 个 `TabItem`（`FlowDocumentScrollViewer`／`PageViewer`／`Reader`，各 `Width=640 Height=400 Margin=32`）承载 Neptune 长文档（含 `<Figure Background="GhostWhite">`／`<Floater Background="GhostWhite">`／`Background="LightGoldenrodYellow"·"LightGray"` 的 `TableRow`／`Beige`＋`DarkGreen` 的 `Paragraph`） |
| `k=23` `RichTextBoxDemo` | `UserControl/Styles/RichTextBoxDemo.xaml` | **否** —— 树为 `hc:TransitioningContentControl` → `RichTextBox Width=400 Height=300 Margin=32` ＋ `FlowDocument`（标题重复 20 次／正文重复 1000 次／`Hyperlink`） |
| 首屏 `PracticalDemo` | `UserControl/Main/PracticalDemo.xaml` | **是（唯一）** —— `<userControl:UnderConstruction VerticalAlignment="Center" HorizontalAlignment="Center"/>`（`:9`） |

**全树判据（现取 `grep -rn UnderConstruction --include=*.xaml`）**：命中 **恰 2 处** —— `UserControl/Main/PracticalDemo.xaml:9`（**唯一的具名使用者**）＋ `UserControl/Main/UnderConstruction.xaml:1`（**控件定义**）。`grep -rln under_construction`（GIF 引用）**恰 1 件** ＝ `UnderConstruction.xaml`。
⇒ **「敬请期待」占位控件 `UnderConstruction` 只服务首屏 `PracticalDemo`；`k=23`／`k=24` 自身无占位。**

### 2.2 运行期侧（现取本趟腿日志）

| # | 现取证据（`app_g1.log`，本席现取） | 它证明什么 |
|---|---|---|
| A1 | `[NS] loaded HandyControlDemo.UserControl.FlowDocumentDemo scope=NameScope …upHits= UP0=FlowDocumentDemo…`（1 行） | **`k=24` 页的 `Loaded` 已触发** ⇒ 该 `UserControl` 已挂进有呈现源的树 |
| A2 | `[NS] loaded HandyControlDemo.UserControl.RichTextBoxDemo …upHits= UP0=RichTextBoxDemo…`（1 行） | **`k=23` 页已加载** |
| A3 | `[GEO]` 现取 `hdr=流文档滚动视图 sel=True`／`hdr=流文档单页视图`／`hdr=流文档查看器`（各 `scr=268,49／440,49／611,49 wh=165x27 vis=True`，共 **15** 行） | 这是 **`k=24` 页自己的**三个 `TabItem`，**已进入主窗口视觉树、已有非零布局** |
| A4 | `leg_24.env`：`ns=HandyControlDemo.UserControl.FlowDocumentDemo`；`session.txt`：`AFTER item=24 … expect_hit=yes`／`CLICK k=24 … ns_last=…FlowDocumentDemo` | 应用自报页身份**命中期望值**（点击打到了目标项） |
| A5 | `[STATE]` 现取 `LB(ListBoxDemo sel=-1/31) → sel=24/31 → sel=23/31` | 交互（点击）**打到了目标项** |

⇒ **判**：`k=23`／`k=24` **确实是** `RichTextBoxDemo`／`FlowDocumentDemo`，且**两页 XAML 自身无占位**。**派单 §① 设的"若靶页本就空态"这一支不成立** —— **不换页、不换腿**，靶页正确。

### 2.3 与帧面对照（本席自算，只读 PNG/GIF）

| 面 | 现取 | 目标页应有 |
|---|---|---|
| 活锚 `GhostWhite`／`Beige`／`DarkGreen`／`LightGoldenrodYellow` | **0／0／0／0 px** | `k=24` 的 Figure/Floater/Table 应有这些色 |
| 占位 GIF 块（`∈ under_construction.gif` 调色板） | **129792 px，`bbox=(317,137,732,448)`**（416×312） | 不应有（那是首屏占位） |
| `y∈[40,86] ∧ x∈[258,790]`（`k=24` 页签带）暗像素 | **6** | `k=24` 三个页签应画在此带 |
| `k23.png ≡ k24.png`（逐字节） | **同 `sha16=ef3fd6765f18f51b`** | 两页内容不同 ⇒ 应不同 |
| `cmp` 本趟 `k24.png` vs 在册 `T-A24` 帧 | **IDENTICAL** | —— |

⇒ **判**：帧画的是**首屏 `PracticalDemo` 的空态占位页**（`T-A24` §2 同一结论；本席独立复算并另加"页签带／命名色锚"两条读数）；目标页**无任何自身像素**。**本趟帧面相对 `T-A24` 零位移**（同 `sha16`）。

> ⚠️ **口径**：`[GEO]` 是**布局面**（`IsVisible` ＋ `ActualWidth/Height` ＋ `PointToScreen`），**不是**"有没有被光栅化"；`ns=` 只证"类型已加载"，**不证**"内容已画"（承裁定族既有口径）。

---

## §3 ② 若无占位 ⇒ 逐层定位第一处断点

### 3.1 分层表（每层给现取证据与判）

| 层 | 本层现取证据（`app_g1.log`，本席现取 `grep -c`／原文） | 判 |
|---|---|---|
| **（0）输入/命中** | `[HCIN]` 222 行；`[STATE] … sel=24/31 → sel=23/31` | **正常** |
| **（1a）native 段落模型（子段/段落表）** | `[FSQSTD]` **702** 行**全部** `rc=0 reason=ok … src=SUBENUM(+136/+144) out=WRITTEN bytes=40 cParas=N true_cParas=N`；`[FSQSPL]` **698** 行**全部** `rc=0 reason=ok … cParas=N made=N`；`[SUBTREE] … v=IN-WINDOW-SUBTREE-BUILT` | ✅ **通** |
| **（1b）native 行模型（驱动＋台账）** | `[FORMATLINE]` **10** 行：3 条窗级 `gate=1 … v=DRIVEN calls=42 ok=7 gap=0 incomplete=0` ＋ 7 条段级 `v=LINES-RECORDED`（`nlines=8/6/6/2 dcp_sum=956/571/595/43 complete=1`）；`[FORMATLINE-LINE]` **42** 行（`dcp/dcpLine/fsflres/ascent/descent/durbbox/pfsline`）；`[TEXTLINE_LSEM]` **12** 行 | ✅ **通（真调且记账）** |
| **（1c）native 查询期文本细节回填（← 断点）** | 🔴 `[FS_PAGE_GAP] rc=-10000 reason=no-text-line-model entry=FsQueryTextDetails … nomodel=1..105 out=UNWRITTEN bytes=0` **105** 行（**全部** `rc=-10000`）；`[HC-UNHANDLED]` **109** 行**全部** `PtsException: … Error code: '-10000'` | 🔴 **在这里断** |
| **（2）DV 几何 / 文本行盒** | `[FSQSTD-SRC] … NOINFO=fsupdinf(no-source),fsrc(declared-geometry)`；`[FSQSPL] … NOINFO=subtrack-para-geometry(dvrUsed/dvrTopSpace/bbox=0)` | **未产出**（因（1c）未过；行盒由（1c）回填） |
| **（3）MIL 命令 / 渲染通道 / `MilChannel`** | `grep -c` 于 `app_g1.log`：`MIL`＝**0**／`MilChannel`＝**0**／`GlyphRun`＝**0**／`DrawInstruction`＝**0**／`RenderTarget`＝**0**／`[RENDER`＝**0**／`[CHANNEL`＝**0** | **取不到**（日志不带渲染层标记）⇒ **`NOINFO-MIL-CHANNEL-COUNT`**；但**因（1c）断在上游，下游无命令可言** |
| **（4）视觉树 / `[VIS]`** | `[VIS]` **108** 行（`children=1 page=… page_qpd=… fstd_since_qpd=1 vis_n=1..108 basis=fmtrackparalist-after-qpdnew-with-1-trackdetails`）；`[QPD]` 652 行 `rc=0 qpd_ok=…`；`[CLRUPD]`／`[FSUPDFSP]` 各 107 行 `rc=0 …clr_ok/upd_ok=…` | **在**（native 侧"页视觉帧"下游见证递增）—— 但**布局面在 ≠ 像素在** |
| **（5）帧面（像素）** | `AE(boot,k24)=15386` 全落左栏（`bbox=(28,169,239,560)`）；`k23≡k24`；活锚全 0 | 🔴 **零像素**（内容区） |

### 3.2 第一处断点（**唯一点名**）

> **断点 ＝ `FsQueryTextDetails` 查询期「回查」未接线。**
> 现取（本席）：`[FS_PAGE_GAP] rc=-10000 reason=no-text-line-model entry=FsQueryTextDetails ctx=… para=… calls=N gap=N nullout=0 nullpara=0 unclaim=0 unknown_ctx=0 nomodel=N out=UNWRITTEN bytes=0` —— **105** 行，且**本趟 `[FS_PAGE_GAP] rc` 分布只有 `-10000` 这一种**（`grep -oE 'FS_PAGE_GAP\] rc=-?[0-9]+' | sort | uniq -c` ⇒ `105 rc=-10000`）。
> **`unclaim=0`／`unknown_ctx=0`／`nomodel` 递增** ⇒ native 侧**认得**这个 `pPara`（入参身份面已通），**只是没有"文本行模型"可回填**（出参面）。
> **因果链**：`FsQueryTextDetails=-10000`（出参一字不写）⇒ 托管 `TextParaClient.ValidateVisual` 抛 `PtsException('-10000')`（`[HC-UNHANDLED]` 109，单一型）⇒ 布局/校验中止 ⇒ 该页视觉**不产出内容绘制** ⇒ 帧内容区零像素、维持在首屏占位态。

### 3.3 与 `T-A24` 的关系（断点**下移一层**，非推翻）

| 面 | `T-A24`（侦察时） | 本趟（`T-A31` 后） |
|---|---|---|
| `[HC-UNHANDLED]` | 427（全 `PtsException('-10000')`） | **109**（全 `PtsException('-10000')`） |
| native 段落查询拒因 | `reason=unclaimable-para`（53）／`reason=unclaimable-subtrack`（370） | **归零**（`FSQSTD/FSQSPL` `rc=0 reason=ok`） |
| 新出现的拒因 | —— | **`reason=no-text-line-model`（105）** |
| 帧面 | `ef3fd6765f18f51b` | **`ef3fd6765f18f51b`（同）** |

⇒ **断点由"段落内容模型不可认领"下移到"文本行模型回填缺失"**；`T-A24` §5.1 选靶 `NATIVE-QUERY-PHASE-CONTENT-MODEL` 的**前半（段落模型）已由 `T-A25` 打通**（提交 `b2ead11`：`unclaimable 341/54→0/0`），**当前前沿 ＝ 其"文本行模型"那一半**。

---

## §4 ③ 唯一选靶 ＋ 理由 ＋ 判据草案

### 4.1 唯一增量（具名）

> **`NATIVE-QUERY-PHASE-TEXT-LINE-BACKFILL`**（＝ `T-A27` 设计草案**路 (丙) 的第 3 步「回查」**；前两步「窗内驱动 `pfnFormatLine`」＋「行记录台账」已由 `T-A28`→`T-A31` 落地）：
> 在 `src/WpfGfx.Linux.Native/src/win32_pts.c` 上，让**查询期**从本侧**行记录台账**（`wpf_pts_subtrack::fl_line[]`，现取由 `[FORMATLINE-LINE]` 打出的**真返回值**）**回填**：
> - `FsQueryTextDetails` ⇒ 出参 `FSTEXTDETAILS`（`fsktdFull`：`cLines`／逐行 `dcpFirst`／`dcpLim`／`dvr*`）；
> - `FsQueryLineListSingle`／`FsQueryLineListComposite` ⇒ 行盒数组（`pfslineclient = pfsline`）；
> - `FsQueryLineCompositeElementList` ⇒ 元素表（`pLine` 用台账行句柄按**来源证据**认领）。
> **未驱动／未造型／认不出身份 ⇒ 仍拒（出参一字不写）**。**落点**：`win32_pts.c`（＋ `bin/exports.txt` 若随动——三入口**已导出**，`FsQueryTextDetails` **已导出**，故预期**不增导出**）。

**理由（逐条，均有 §3 现取证据）**：
1. 现取的"断"**唯一**在（1c）：`[FS_PAGE_GAP] rc=-10000` **只有** `no-text-line-model` 一种 reason，且**只出自 `FsQueryTextDetails`**（`entry=` 分布现取 105/105）。
2. **上游两步已通且真**：`[FORMATLINE] v=LINES-RECORDED`（7 段、`complete=1`）＋ `[FORMATLINE-LINE]` 42 行台账**已含**回查所需字段（`dcp_first/dcp_lim/dvr_ascent/dvr_descent/dur_bbox/pfsline`）。
3. **不是"三源缺失"**：`T-A27` §4.1 已判"行断器＋字符源＋度量"在宿主侧（shim）**已存在且已接在 PtsHost 行排版链上**（**引自该件，未独立复算**）；本趟 `[FORMATLINE] v=DRIVEN` 正是**运行期**反证该判（native 真驱动 `pfnFormatLine` 成功）。
4. **下游全层**在同帧内被证**健康**（左栏 ListBox 有像素位移、窗口框/占位图都画得出）⇒ 把（1c）接通是**唯一**能同时解释"两页零像素"与"其余内容正常"的增量。
5. **触 `fp_inputs()`**：`src/WpfGfx.Linux.Native/src/**` 在覆盖面内 ⇒ 流程上须排在采样前并同趟过 `[42] --fp-manifest --expect`。
6. **代价如实**：**不是确定的一跳** —— 回填要**先答两问**（§5 的两条 `NOINFO`）：① 真机字段映射（`pfslineclient`↔`pfsline`／`dcpFirst`↔累计 `dcp`）；② 台账里 `pfsline` 的**真身**（现取 `[FORMATLINE-LINE] … pfsline=0xc/0xd…` 是**小值句柄**，**非**本例可 deref 的指针）⇒ 若消费者要真行指针，则本增量**至少还含一跳"行对象台账"**。

### 4.2 判据草案（4 条可证伪 ＋ **反极性必红腿**）

| # | 判据（可证伪的单行式） | **反极性（必红腿）** |
|---|---|---|
| **D1 零假值／出参纪律** | 拒绝路径出参**一字不写**（承 `[FS_PAGE_GAP] … out=UNWRITTEN bytes=0`）；成功路径**只在**回填真值时出现 `out=WRITTEN bytes>0`。 | 为让 `rc=0` 好看写**常量** `cLines`（或写 `0`）⇒ 消费者读成"0 行"⇒ **静默丢整段** ⇒ **必红**（`P8` 恒绿陷阱，裁定四十八 (c)）。 |
| **D2 永不假成功（账守恒）** | `FsQueryTextDetails` `rc=0` **仅当**：行记录真来自 `pfnFormatLine` 返回值 ∧ 段内账守恒（`Σ dcpLine == 该段符号数`，末行 `fsflres` 收束）∧ 几何有源。 | 返 `rc=0` ＋ 常量／估算 ⇒ 伪成功 ⇒ **必红**（做法：D2 加一条"`true_cParas`／`cLines` 必须等于窗内枚举／台账真值"）。 |
| **D3 失败必留痕 ＋ 计数恰涨 1** | 任何拒绝**必**打具名行（`entry=` ＋ `reason=` ＋ `calls/ok/gap`）且 `gap` **恰涨 1**（承 `[FS_PAGE_GAP]` 现状）。 | 静默 stub（返非 0 零痕迹）⇒ 与"真 0 次调用"**不可分** ⇒ **必红**。 |
| **D4 帧面必须长像素（**判"接了但没生效"**）** | `k=24` 帧里目标页具名色锚（`GhostWhite/Beige/DarkGreen/LightGoldenrodYellow`）各 `≥200px`，**或** `y∈[40,86] ∧ x∈[258,790]` 暗像素 `>0`（今天 0／6）；且 `AE(boot,k24)` 的差异 bbox **必须落内容区（x>240）**（今天 `bbox=(28,169,239,560)` **全在左栏** ⇒ 红）。 | 只有那块 416×312 占位图（`∈ under_construction.gif`，`129792 px`）⇒ **必红**；把 `k23≡k24`（`AE=0`）当绿 ⇒ **必红**。 |

**附加（先做的判别实验，最便宜）**：现成反序腿 `clicks=[23,24]`（`session_inner.sh` 现取为 `[24,23]`）＋异页腿（先点一个**非 PTS 页**）⇒ 用来把"（1c）层断"与"呈现面冻结"分开（承 `T-A24` §5.2 附加，未做）。判：**若异页腿内容区出现像素变化** ⇒ 内容面板能重绘 ⇒ 唯一阻塞＝（1c）；**若不出现** ⇒ 另有一处呈现面阻塞。

### 4.3 另两个选项（**不推荐**，如实并列）

- **合法终点**：判「本增量在现写域内不可做」并具名前置 —— 但现取**反驳**之：台账**已有真值**（`[FORMATLINE-LINE]` 42 行），故**不构成合法终点**（这是本趟与 `T-A20`／`T-A26` 时代的关键差别）。
- **换靶／换腿**：**不** —— 靶页身份正确且无自身占位（§2），换页无据。

---

## §5 ⑤ 具名 `NOINFO`（逐条给"消掉需要什么"）

| # | `NOINFO` | 现取依据 | 消掉条件 |
|---|---|---|---|
| `NOINFO-MIL-CHANNEL-COUNT` | **MIL 命令／渲染通道／`MilChannel` 的按命令计数** | `grep -c` 于 `app_g1.log`：`MIL`／`MilChannel`／`GlyphRun`／`DrawInstruction`／`RenderTarget`／`[RENDER`／`[CHANNEL` **全 0** | 开一条渲染侧通道日志（如 `WPF_LINUX_MIL_LOG`）或插桩 `MilChannel`／`MilCommandDispatcher`（本趟**未开**）。**边界**：（1c）断在上游 ⇒ 下游**本无命令**，此条**不影响本件结论** |
| `NOINFO-HOSTLINE-NATIVE-BACKFILL-SEMANTICS` | 真机 `FsQueryTextDetails`／`FsQueryLineList*` 从行记录回填的**确切字段映射**（`pfslineclient`↔`pfsline`／`dcpFirst`↔累计 `dcp`） | 本席只取到结构面（`FSTEXTDETAILS` 判别联合 ＋ 台账字段），**未实测**真机语义 | 一条**真机**（Windows）对拍，或 native 侧真实现后自证（与 `T-A27` §5 同条，**非本席复算**） |
| `NOINFO-LEDGER-PFSLINE-DEREF`（**本轮新读出**） | 台账里 `pfsline` 的**真身**（能否 deref 成真行对象） | 现取 `[FORMATLINE-LINE] … pfsline=0xc / 0xd …`（**小值句柄**，非本例可 deref 的指针）；`FsQueryLineCompositeElementList` 的 `pLine` 需按身份认领 | 读回填实现所需的确切契约（行句柄是否只作**不透明标识**用）；若需真行对象 ⇒ 本增量须**再加一跳"行对象台账"** |
| `NOINFO-CONTENT-PANEL-FREEZE` | **「内容面板像素停在切页前」的机制**（呈现面未重绘 vs 旧视觉保留式绘制） | 本席只能证"布局在（`[GEO]`／`[VIS]`）而像素不在（§2.3）"；**分不开**：①断点致新子树无绘制命令；②旧子树绘制仍在 | 一帧**绘制命令侧**读数（见 `NOINFO-MIL-CHANNEL-COUNT`）；或 §4.2 的**判别实验**（异页腿） |
| `NOINFO-K23-AE0-AMBIGUITY` | `k=23` `AE=0` 的歧义（"两页同貌" vs "第 23 页没重绘"） | `clicks=[24,23]`（23 是**第二击**）⇒ 无法排除"23 只是没重绘" | 跑 `clicks=[23,24]` 反序腿（便宜；本席**只登记**） |
| `NOINFO-FSGEOMETRY-LAYOUT`（承 `T-A28`／`T-A31`，**未消**） | `pfnFormatLine` 用的页几何（`WPF_PTS_FL_DU/DV=180000`)的**入站源** | 台账内 `[FORMATLINE] … geo=self-page-geometry(768x576,same-as-FsCreatePageFinite)`／窗级 `geo=NOINFO-FSGEOMETRY-LAYOUT` | 上游 ABI 几何来源（本侧**沿用自己的约定**，**不**声称与上游可比） |

---

## §6 边界 · 纪律 · 自证

1. **写域**：**唯一**新增件 ＝ 本载体。现取 `git status --porcelain`（**两项均先于本件**，全属他人）：`?? build/MilBridge/tasks-tail2/T-A32.md`、`?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log`。
2. **只读**：本件命令为 `sha256sum`／`grep`／`sed`／`head`／`tail`／`wc`／`cmp`／`ls`／`git log`／`git status` ＋ **纯读** Python（只解 PNG/GIF 像素）＋ 对第三方 demo 源（`~/hc-linux/src/Shared/HandyControlDemo_Shared/**`）与仓外腿目录（`~/tA31-work/legs-newdef/**`）的**只读** `grep`／`cat`（**未写、未运行**）。**零构建、零跑腿、零显示位、零整趟门禁、零 `git` 写。**
3. **不引他人读数当证据**：`T-A24`／`T-A27`／`T-A28`／`T-A31` 只在 **§0/§3.3/§4** 的理由里作**对照引用**并逐处标「未独立复算」；本件所有数值（帧像素、`AE`、`grep -c`、`[GEO]`／`[NS]`／`[FS_PAGE_GAP]` 原文、`sha16`）**均为本席现取**。
4. **跨代／跨装置不可比（纪律 31/32）**：本件 §2／§3 的成对比较**同趟同代**（同 `app_g1.log`、同 `shim=ac002caa324a496f`）；`T-A24` 的在册帧只作**逐字节 `cmp` 对照**，不作结论承重件。
5. **口径纪律**：`[GEO]`／`[VIS]` 是**布局/见证面**，**不是**绘制面；`ns=` 只证"类型加载"；`ENFE`（**0**）与 `[HC-UNHANDLED]`（**109**）**各自定义、不互折**；`reason=ok`（`FSQSTD`／`FSQSPL`）≠ 内容已画。
6. **未做**：未判相位；未动任何判据件/牙；未跑门禁；**未实现任何增量**（本件**只侦察＋复核＋选靶**）；未新增任何 `D-G<digits>` 登记编号。

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-render-recon.md | sha256sum | cut -c1-16`）= `3f29417c4c7f59ef`

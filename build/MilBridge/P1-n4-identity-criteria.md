# P1-W62 · `N4` **正身份**取证路径侦察 ＋ 判据草案 —— 今天有哪几条路能证「帧里画的是真内容」

> **本件是判据／侦察件**：**不构建、不跑腿、不占显示位、不跑整趟门禁、不 `git add/commit/push`**；**不碰** `src/**`（`runner` 的 `t141` 在飞）、**不碰** `build/MilBridge/tools/**`、**不碰**任何 `.cs`。
> **唯一写入** ＝ 本件 `build/MilBridge/P1-n4-identity-criteria.md`。
> **一切读数由我现取**（命令与输出原样贴出）；引他人载体**逐处带代际（`sha16`）＋取值时刻**并标注「引自 X，本席未独立复算」；**不预填任何运行期读数**（缺格一律 `NOINFO`）。
> **读取时刻**：`ts=2026-09-29T14:27:21.163+0800`（起点）→ `ts=2026-09-29T14:28:53.045+0800`（末取）。

---

## §0 现取快照

| 项 | 现取值 | 取法 |
|---|---|---|
| `HEAD` | **`208ee11`**（`fix(#81): t137 line_is_hist 锚族按具体形状扩+dated 第二必要件（SITE-DRIFT 1->0, selftest 12/0->15/0）+ 裁定三十三第二次附记（认账第11次）+ cell=#1 同代对齐`） | `git log --oneline -3` |
| 判据面（`N4` 原文所在件） | `build/MilBridge/P1-realized-criteria-report.md` ＝ **`281b40613d6f1f34`**／**214 行**／`mtime 2026-09-29 14:15:43.851292405 +0800` —— **与队长所给值逐位相符（本席自己现取复核）** | `sha256sum`／`wc -l`／`stat` |
| 守卫 | `build/MilBridge/tools/pts-pages-guard.sh` ＝ **`201eca63e6820011`**／**1068 行** | `sha256sum`／`wc -l` |
| 帧面（本席现算） | `boot.png` ＝ **`b21eb530afd3c66c`**（386 色）｜`k23.png` ＝ `k24.png` ＝ `last.png` ＝ **`ef3fd6765f18f51b`**（各 383 色） | `sha256sum`／PIL |
| 窗口几何（本席现算，**内容区的客观定义就用它**） | 两帧的**非黑 bbox 均 ＝ `(0,0)-(799,599)`**、白 bbox ＝ `(1,1)-(798,598)` ⇒ **应用窗口 ＝ 左上角 800×600** | PIL bbox 扫描 |

---

## §1 ① 先读判据面（逐字引，两处都自己现取）

### 1.1 `N4` 原文（`P1-realized-criteria-report.md`，`281b40613d6f1f34`／214 行；**本席未独立复算其内任何读数**）

> **objective**：证明"画面是该页**自己的内容**"，而不是应用的空态页。
> **acceptance（逐字）**：① **负身份**（今天可达）＝ `N1①` 的帧身份（∉ 空态参照集）；② **正身份**（今天**无载体**）＝ 必须给出**该页专属**的期望指纹（例如登记一次已知良好渲染的帧 `sha256`，或该页专属的结构读数如 `TabControl` 的 tab 数）；③ **`ns=` 不得单独**承担内容身份；④ 在没有 ② 之前，本条记 **`NOINFO(无正身份载体)`**，**不得折绿**。
> **取哪个字段／期望形状**：帧 `sha256`／`LEG … ns=`／内容 token 命中数。**期望**：帧 `sha256` ＝ **登记的期望指纹**（今天**无此登记** ⇒ `NOINFO`）；`ns=` 只作**辅助**。
> 同件 dated 段（`t118`）另立 **`N4` 取（甲）**：登记为「**待补**」，**补的条件 ＝ `FsCreatePageBottomless`（及其后 `FsCreatePageFinite`）真落地、两页首次各自绘出内容之后**（可判标志：`ENFE_TOTAL=0` **且** `k23.png` 与 `k24.png` 的 `sha256` **不相等**）；**责任人 ＝ 当趟实现件的写者**（同趟登记该页专属期望指纹，落点＝该件 dated 段）；**复核方 ＝ 独立复核者**（下一件独立复算该指纹可复现）。

### 1.2 `PTS_N4_POSITIVE_FP` 的**现行语义与取值形状**（守卫 `201eca63e6820011`，逐字引）

```
: 486  `n4`     ＝ env `PTS_N4_POSITIVE_FP="<k23 sha16>,<k24 sha16>"` 与两腿 `fr_sha` **逐位相同**
                  （＝`N4` 正身份的**登记载体**；**未登记** ⇒ `NOINFO(no-registered-positive-identity)`，不给绿）；
: 501    if [ -n "${PTS_N4_POSITIVE_FP:-}" ]; then
: 502      if [ "${PTS_N4_POSITIVE_FP}" = "${N1_SHA_23},${N1_SHA_24}" ]; then _pos="${_pos:+$_pos,}n4"; else _n4miss=1; fi
: 520    echo "PTS_N1_POS=phase=$PHASE positive=${_pos:-none} n4=${PTS_N4_POSITIVE_FP:-absent} anchor_hits=$_anchor differ=$_differ via=${_via:-none} n4_unregistered=$_n4miss exception_proof=… exception_applies=$_exgo（三源口径见 t136 段；「∉ 参照集」单独**不给绿**）"
: 522-530  PTS_N1_GATE = NOINFO（必要件取值缺）／PASS（`_pos` 非空）／EXCEPTION（N3 例外支）／
                     FAIL positive=none … reason=only-necessary-condition-no-positive-evidence
```
另两条正证据源（同段，逐字）：`anchor` ＝ `$PTS_CONTENT_ANCHOR_RE`（**默认 `[Nn]eptune`**）在 `<dir>/app_g1.log` 命中数 `>0`；`differ` ＝ 两页帧 `compare -metric AE` 实测 `>0`（或两腿 `fr_sha` 不等）。
空态参照集：`Pts-pages-guard.sh:98 FRAME_EMPTY_SET="1a76488aa4a790b3,ef3fd6765f18f51b"`。

🔴 **本件对 `PTS_N4_POSITIVE_FP` 现行语义的一条读数（本件最重要的口径发现）**：它的**全部**判定就是「**声明值 == 实测的两腿 `fr_sha` 拼接**」—— **它本身不含任何"这枚帧里画的是真内容"的证据**。⇒ **只要把今天的两腿 `fr_sha` 原样写进该 env，`n4` 源就会亮**，即**存在一条"登记即算"的声明式假绿通道**（承 `t136` 把要件①降为**必要非充分**的精神：**它也必须被绑到一条独立可证伪读数上**）。本件 §3-C-X 据此立一条硬约束。

---

## §2 ② 候选路径盘点（逐条给 可行性／代价／**可证伪形态**／`NOINFO` 面）

> **先给一条口径（写死）**：一条读数算"**正身份证据**"，当且仅当**存在一个应当与它不同的反极**（＝**能证伪**）。**恒真的量不算**（`ink>0` 今天恒真 ⇒ 已在本会话被**禁用**为正身份；「`fr_sha` ∉ 空态参照集」已被 `t136` 降为**必要非充分**）。**本件不把这两样当正身份，也不把它们混进 `magenta`／`colors` 的口径里。**

### 2.1 (a) **内容锚** —— 拆成两条子路，**一条活、一条死**（都有本席现算读数）

**a1 · 精确色锚（活；k=24 可判，k=23 无）**
- **从内容定义到帧可判特征的链条（可复算）**：`FlowDocumentDemo.xaml`（**仓外只读**；`~/hc-linux/src/Shared/HandyControlDemo_Shared/UserControl/Styles/FlowDocumentDemo.xaml`）逐行给出**具名色**：
  `:21 Figure Width=140 Height=50 Background=GhostWhite`｜`:22 Paragraph Background=Beige Foreground=DarkGreen`｜`:26 Floater Background=GhostWhite Width=285`｜`:38`／`:54 `TableRow Background=LightGoldenrodYellow`｜`:46 TableRow Background=LightGray`｜`:85`／`:86` 第二组 `Figure/Floater`（同色）｜`:104`／`:107`／`:110` 三个 viewer `Width=640 Height=400 Margin=32`。
  ⇒ 这些**具名色**在 WPF 里是**定值 RGB**（`Beige`=(245,245,220)／`DarkGreen`=(0,100,0)／`GhostWhite`=(248,248,255)／`LightGoldenrodYellow`=(250,250,210)／`LightGray`=(211,211,211)）⇒ **该页真绘出内容时，帧里必然出现这些像素**（成片填充，不是单像素）。
- 🔴 **本席现算的标定（这就是这条路的可证伪性证据）**：对现盘三帧逐色计数 ——
```
boot.png  Beige=0 DarkGreen=0 GhostWhite=0 LightGoldenrodYellow=0  LightGray=44 White=203900 Black=830720
k23.png   Beige=0 DarkGreen=0 GhostWhite=0 LightGoldenrodYellow=0  LightGray=51 White=197604 Black=830720
k24.png   Beige=0 DarkGreen=0 GhostWhite=0 LightGoldenrodYellow=0  LightGray=51 White=197604 Black=830720
```
  ⇒ **`Beige`／`DarkGreen`／`GhostWhite`／`LightGoldenrodYellow` 四色现取 0 像素**（＝空态页里根本没有）⇒ **它们是**活**锚：今天"缺席"就是**红**，将来"成片出现"就是**正证据**。
  ⇒ 🔴 **`LightGray` 是死锚**：空态帧里**已经有 44/51 像素** ⇒ **不得**当 k=24 的锚（这条**只有实测才知道**，算不出来）。
- **k=23 无精确色锚（诚实记）**：`RichTextBoxDemo.xaml` 现取只有 `Margin=32 Width=400 Height=300` 与三段 `<Paragraph>`（其一 `<Hyperlink>https://github.com/NaBian/HandyControl</Hyperlink>`）；**没有**自定义背景/前景色 ⇒ **黑字白底**，与空态页的正文**同色系** ⇒ **色锚这条路对 k=23 是死的**（除非用 Hyperlink 的主题色，而那**依赖主题**、不可复算 ⇒ 记 `NOINFO`）。
- **代价**：一枚 `python3 + PIL` 脚本（本机**有**，见 §2.5）或 `convert -format %c histogram:`；**每帧 <1 s**；**零新仪器**。
- **`NOINFO` 面**：① 锚只覆盖 **k=24**；② 它证"该页文档的**某些段落/图/表**被绘出"，**不**证"整页排版正确"；③ `Figure/Floater/Table` 的**布局位置/尺寸**不由色锚承担（要位置就得另立区域读数）。

**a2 · 文本串锚（死；需 OCR，本机没有）**
- 守卫现用的 `PTS_CONTENT_ANCHOR_RE` 默认 `[Nn]eptune` 是**在 `<dir>/app_g1.log` 里 grep**（**日志**，不是帧）—— 它证的是"应用**读过/打过**这些字"，**不证帧里画出来了**。（这也是它今天命中 `0` 的原因；且即便命中，也属"日志侧"证据。）
- **要在帧里认字** ⇒ 需 OCR ⇒ **本机 `tesseract`/`gocr` 现取 ABSENT**（§2.5）⇒ **`NOINFO(本机无 OCR)`**；替代 = 走 a1（色锚）或 c/d（结构面）。

### 2.2 (b) **正向参照帧** —— **今天不存在**（本席实测，非推断）

- **实测**：全仓 `*.png`（排除 `.git`／`obj`／`bin`）共 **275** 枚；按尺寸分组的前几位是 `256x256`×179、`240x180`×34、`320x220`×21、`460x90`×12；**尺寸为 `1280x1024`（＝本装置腿的帧尺寸）的只有 8 枚**，且**逐条现取**它们全都落在两处：
  `build/MilBridge/tests/PtsPagesProbe/evidence/shots/g1/{boot,k23,k24,last}.png` 与 `…/evidence/arm_A/shots/g1/` 的**同名 4 枚**（同一批帧的两份拷贝）。
  其余 267 枚是**探针/golden 图**（`tests/golden/*` 名为 `animate_static_end_value.png`／`clip_path.png`／`drawing_brush_*` 等，与 hc 演示页无关）。
- ⇒ **在册没有、仓内也没有一枚"这两页真内容渲染"的帧** ⇒ 具名前置 **`PRECOND-KNOWN-GOOD-FRAME`**（要谁来给、代价见 §4）。
- **⚠️ 对 `N4` 取（甲）的一条收紧（本件必写）**：(甲) 说"登记**一次已知良好渲染**的帧 `sha256`"。**但"已知良好"这件事本身需要证据** —— 若拿"第一次恰好出现的帧"直接登记，就把**未知**当成了**已知**（今天的空态帧就是活例子：它当年也"第一次出现"过）⇒ **登记必须附一条本节 (a)／(d) 的独立可证伪读数**，**否则该登记只是声明**（见 §3-C-X）。

### 2.3 (c) **结构／统计读数** —— 逐条判"能不能证伪"

| # | 量 | 今天现算 | **能证伪吗** | 判定 |
|---|---|---|---|---|
| c1 | `ink = W×H − magenta − dominant` | 四帧**全 ＝ 480000** | ❌ **恒真**（`dominant` 恒为黑 830720） | **禁用为正身份**（`t116`／`O-4` 口径；本件照守） |
| c2 | `magenta` 像素数 | 四帧**全 0** | ➖ 它证伪的是"**占位还在**" | **负身份**，不是正身份 |
| c3 | `colors`（去重色数） | boot 386／k23·k24 383 | ⚠️ 变动**不等于**内容（值域窄、可由**边框/滚动条**驱动） | **必要非充分**；**不得单独发绿** |
| c4 | **行带数**（非底色像素的连续行带） | 四帧**全 ＝ 1** | ❌ 四帧同值 ⇒ **零区分力**（成因：`dominant=黑` 而窗口在左上角 ⇒ 非底色像素连成一片） | 🔴 **死**（这条是**实测**出来的死法，不是推的） |
| c5 | **内容区裁剪后**的非底色像素数（区域限制） | 内容区客观定义 ＝ **窗口 800×600 减去左侧导航**：窗口 bbox 现算 `(0,0)-(799,599)`；导航 rect 现取 `[GEO] ListBox#ListBoxDemo scr=28,166 wh=203x389` ⇒ 内容区 ≈ `x∈[232,799]×y∈[92,599]` | ✅ **可能**：需要**标定**（用今天的两枚空态帧当"反极"，要求未来帧在该区域内超出空态基线**若干倍**） | **候选（需标定）**：代价低，但**阈值必须先由反极标定**，不许先写死 |
| c6 | 连通域计数／文本行检测 | 本机有 `PIL`／`numpy`／`convert` ⇒ **技术上可做** | ✅ **可能**（空态是"一张插画＋一行字"；真内容是"多段文本＋表＋图" ⇒ 结构分布不同） | **候选（需标定＋需承认它是"看起来像"的代用品）**：**不得**只靠它单独发绿 |
**⇒ (c) 一节的结论**：结构统计里**只有"区域限制 ＋ 反极标定"这一族**有希望，**且必须逐项拿今天的空态帧当反极先标定**；`ink`／行带数已被**实测**排除。

### 2.4 (d) **托管侧读数** —— 逐条判

| # | 量 | 现状（本席现取） | **能证伪吗** | 判定 |
|---|---|---|---|---|
| d1 | `ENFE_TOTAL` | 现取日志 `84db0eb62d15e0b2`（`mtime 14:12:09.729130105`）内 `Unable to find an entry point named` ＝ **0** | ➖ **必要非充分**（`t140` 已证：**符号在**≠**内容画出来了**） | **不得**当正身份 |
| d2 | `[GEO]` 视觉树几何（**现成仪器**） | 现取 **927** 行 `[GEO]`；**内容侧元素一个都没有**：`nm=DocumentPage` **0**／`nm=ContentControl` **0**／`nm=ContentPresenter` **0**／`nm=FlowDocumentScrollViewer` **0**／`nm=AdornerDecorator` **0**；`[GEO]` 只打**窗口按钮 ＋ 3 个 `TabItem`（`hdr=HandyControlDemo.Data.DemoInfoModel`）＋ `SearchBar` ＋ `ListBox#ListBoxDemo n=31` 的 31 个导航项** | ❌ **这一面根本没有内容区** | 🔴 **作为内容身份：死**。要用它 ⇒ **必须新加一条"内容区视觉树 dump"**（枚举 `DocumentPage`／文档后代 ＋ 几何）⇒ **具名前置** `PRECOND-CONTENT-TREE-DUMP` |
| d3 | 绘制路径留痕（如 `GlyphRun`／文本行计数） | 现取**没有**任何"该页绘了几行／几个 glyph"的托管计数器（本件只查了 `[GEO]`／`[HC-UNHANDLED]`／`[NS]`／`[STATE]`／`[POP]` 这几个面） | ✅ **可能**（是**与内容绑定**的量，且可为 0 ⇒ 可证伪） | **候选（需新仪器）** ⇒ `PRECOND-CONTENT-DRAW-COUNTER` |

### 2.5 (e) **外部工具**（本席现取 `command -v` ＋ import）

```
tesseract=ABSENT   ffmpeg=ABSENT   magick=ABSENT   gocr=ABSENT
compare=/usr/bin/compare   convert=/usr/bin/convert   identify=/usr/bin/identify   python3=/usr/bin/python3
PIL 9.0.1 ／ numpy 2.2.6
```
⇒ **可做**：像素级/颜色级/区域级测量（PIL／numpy／ImageMagick CLI 全在）；**不可做**：OCR（无任何 OCR 二进制）、视频/GIF 解码（无 `ffmpeg`；`convert` 可读 GIF 单帧，够用于本件的空态插画，但**不作为**身份证据）。
⇒ **替代**：a1 的色锚（纯像素计数，**零新依赖**）优先；需要"文本存在性"时走 d3 的托管侧计数器（**而不是** OCR）。

---

## §3 ③ 每条路径的判据草案（`objective`／`acceptance`／`verify`／两极化）

> **通用**：verify 必须**捕获式取 `rc`**；**两极化 = 正极 ＋ 反极**，**反极必须是"看起来像真内容、其实是空态/占位"的夹具**；**反腿未红 ⇒ 该条不成立**。
> **通用反过读（写死）**：本件任何一条的绿**只**准许读成「**该读数为真**」这一件事 —— **不得**读成"两页真排版"，**不得**拿它替代 `N1`／`N3`。

### C-A **色锚正身份（k=24；本件首选，今天即可落地）**
- **objective**：证明 **k=24 的帧里出现了该页文档**特有**的成片颜色**（＝该页内容**至少部分**真绘出）。
- **acceptance（可证伪，逐条）**：① 锚集**逐色具名**：`Beige(245,245,220)`／`DarkGreen(0,100,0)`／`GhostWhite(248,248,255)`／`LightGoldenrodYellow(250,250,210)`（**四条都是"今天 0 像素"的活锚**）；② **每条锚的计数 ≥ 阈值 `T`（`T` 由"成片填充"的下界定，建议 `T ≥ 200 px` —— 理由是 `Figure 140×50` 的最小成片面积 ＝ 7000 px，`T=200` 只是"确实存在"的保守下界）**；③ **`LightGray` 不得入锚**（空态帧现取已有 44/51 px ⇒ 死锚）；④ **反极必须红**：把**现盘空态帧**（`ef3fd6765f18f51b`／`1a76488aa4a790b3`）喂进来 ⇒ **四色计数全 0 ⇒ 判红**。
- **verify（单行）**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D=build/MilBridge/tests/PtsPagesProbe/evidence/shots/g1; python3 - <<'PY'
from PIL import Image
import collections
anchors={"Beige":(245,245,220),"DarkGreen":(0,100,0),"GhostWhite":(248,248,255),"LightGoldenrodYellow":(250,250,210)}
for f in ["k24.png","boot.png"]:
    im=Image.open(D+"/"+f).convert("RGB"); c=collections.Counter(im.getdata())
    print(f, {k:c.get(v,0) for k,v in anchors.items()})
PY
```
- **期望形状**：真内容帧 ⇒ 四色**各自 ≥ 200**（且**至少两条**非零，避免单色偶然）；空态帧 ⇒ **四色全 0**（今天实测如此）。
- **两极化**：**正极** = 将来某趟真绘出的 k=24 帧；**反极** = 现盘空态帧（**必须有**，且今天就能跑）；**加强反极** = 把 `UnderConstruction` 空态插画**贴到** `Figure` 位置的合成图（由 (d3) 派生或手工合成）⇒ **仍须判红**（因为它没有 `Beige/DarkGreen` 成片）。

### C-B **区域限制 ＋ 反极标定的像素位移（k=23／k=24 通用，**次选**）**
- **objective**：证明**内容区**发生了**远超"非内容变化"的位移**（注意：**`AE>0` 本身不给绿** —— 它已被 `t136` 归为必要件）。
- **acceptance**：① 内容区**客观定义**（不许手画）：窗口 bbox `(0,0)-(799,599)`（现算）**减去**导航 rect `[GEO] ListBox#ListBoxDemo scr=28,166 wh=203x389`（现取）⇒ `x∈[232,799] × y∈[92,599]`；② 读数 = **该区域内** `AE(空态参照帧, 本帧)`；③ 阈值 `T` **必须由反极标定**：用**今天已知的"非内容变化"**（导航高亮/选择态）当标定源 —— 现取全屏 `AE(k23,k24)=0`、`AE(boot,k24)=15386`（**全屏**口径）⇒ **区域内**的相应值**本件不预填**，由实现件同趟标定；④ **反极**：只改导航选择态（内容不动）⇒ 必须**不**过阈值。
- **verify**：`compare -metric AE -crop 568x508+232+92 <ref>.png <frame>.png null:`
- **`NOINFO` 面**：阈值与区域定义**都要标定**，且它**仍只是"变了多少"**，**不证"变成了该页的内容"** ⇒ **必须与 C-A 或 C-D 合用**，**不得单独发绿**。

### C-C **`N4` 登记位加固（`PTS_N4_POSITIVE_FP`；**本件最要紧的一条**）**
- **objective**：堵住 §1.2 那条"**登记即算**"的声明式假绿通道。
- **acceptance（写死）**：`.env`／调用方登记 `PTS_N4_POSITIVE_FP="<k23 sha16>,<k24 sha16>"` 时，**必须同时**给出：① 该两枚帧的**来源**（哪一趟、`DEV … shim=`／`pf=`、`session.txt` 的 `ts`）；② **至少一条**独立可证伪读数**支撑"这两枚帧里画的是真内容"（C-A 的色锚计数、或 C-D 的托管计数），**逐条给读数与阈值**；③ 该支撑读数**必须同趟可复跑**（命令写进载体）。**缺 ②③ 的登记 ⇒ 判"声明式登记" ⇒ 不给绿**（判词建议 `N4-DECLARED-ONLY`）。
- **verify（形状）**：登记处必须能现读到"支撑读数 ＋ 其命令 ＋ 其值"，否则红。
- **两极化**：**正极** = 有支撑读数的登记 ⇒ 绿；**反极** = **把今天两腿 `fr_sha` 原样登记**（无任何支撑）⇒ **必须判"声明式登记" ⇒ 红**（今天就能跑这条反极）。

### C-D **托管侧内容面（**需新仪器** ⇒ 具名前置）**
- **objective**：从**与内容绑定**的托管读数证"该页绘出了内容"。
- **acceptance**：`PRECOND-CONTENT-TREE-DUMP`（内容区视觉树 dump：枚举 `DocumentPage`／文档后代 ＋ 几何）**或** `PRECOND-CONTENT-DRAW-COUNTER`（按页计数：文本行数／glyph 数／`DocumentPage` 数），**且该量可为 0**（⇒ 可证伪）；**反极** = 空态页 ⇒ 计数 **0**。
- **`NOINFO` 面**：今天**两个前置都不满足**（现取 `[GEO]` 无内容侧元素、无绘制计数器）⇒ **本条的格今天一律 `NOINFO`**。

---

## §4 ④ 排期含义（**写死；不要建议现在就翻相位**）

1. **`N4` **今天不是**相位翻转的瓶颈。** 现取三条足以否决翻转：**`N3` 判红**（两页帧 `ef3fd6765f18f51b` 同值、`AE(k23,k24)=0` ⇒ 去重 1，不满足"必须不同"）；**`N4` 无载体**；**`N1` 正证据三源全不在场** ⇒ `realized` 期新闸**必红点名**（守卫现取 `:530` 就是这样一处）。**⇒ 相位翻转的当前阻塞项是 `N3` ＋ `N1` 的正证据闸，`N4` 是它们的**共同上游**。**
2. **先做什么（阻塞顺序）**：① **让两页各自真绘出内容**（`Fs*` 族之后那批托管侧工作；`t140` 的**最小驱动探针**是它的第一个问句）；② 一旦"两页帧 `sha256` 不相等"出现（＝(甲) 里那个可判标志），**同趟**按 **C-C** 登记 `N4`（**必须带 C-A 的支撑读数**）；③ 然后 `N1`／`N3` 才有翻绿的物理基础。
3. **`N4` 何时才变成瓶颈**：**当且仅当**出现"两页帧不同 ∧ `N1` 必要件齐 ∧ `N3` 绿"而 `N4` 仍无登记时 ⇒ 那时它从"上游前置"变成"**最后一道闸**"。**今天不满足该条件 ⇒ 本件只是提前备料**（这正是任务书要求的口径）。
4. **本件**不建议**、也不支持**现在翻相位；**准许的下一步**是：把 **C-A** 落地成一条**今天就能跑**的读数脚本（它今天**必红**——因为空态页四色全 0），
   作为"将来真绘出内容时同趟变绿"的**预先就位的判据**；以及按 **C-C** 把登记位的"支撑读数"要求写进翻转包。

---

## §5 ⑤ 诚实边界 ＋ `NOINFO`／`PRECOND` 清单

**诚实边界（写死）**
- **不声称两页已排版**：现取两页帧**逐字节相同**且是**空态页**；本件所有读数都只是"取证路径的可行性"，**不是内容证据**。
- **不许**把 `ink>0`、**不许**把「`fr_sha` ∉ 空态参照集」当正身份（前者恒真；后者已被 `t136` 降为必要非充分）。
- 证据链缺环 ⇒ **具名 `NOINFO` 或具名 `PRECOND-*`**，**不许**用"看起来像"补洞。

| # | 项 | 状态 | 消掉需要 |
|---|---|---|---|
| N1 | **k=23 的正身份** | `NOINFO(该页 XAML 无自定义色锚；本机无 OCR)` | 托管侧内容计数器（C-D）或 OCR（本机缺） |
| N2 | **正向参照帧** | `PRECOND-KNOWN-GOOD-FRAME`（全仓 275 PNG 里 `1280x1024` 只有 8 枚，全是**同一批 4 帧的两份拷贝** ⇒ 无正参照） | 一次真绘图腿产出的帧 ＋ **C-A 支撑读数**（不许只看"第一次出现"） |
| N3 | **登记位 `PTS_N4_POSITIVE_FP` 的支撑读数** | `NOINFO(守卫今天只比"声明==实测"，不含内容证据)` | 按 C-C 落地 |
| N4 | **区域限制 AE 的阈值与区域定义** | `NOINFO(阈值须由反极标定；本件不预填)` | 实现件同趟用空态帧标定 |
| N5 | **内容区视觉树 dump** | `PRECOND-CONTENT-TREE-DUMP`（现取 `[GEO]` 无 `DocumentPage`／`ContentControl`／`ContentPresenter`／`FlowDocumentScrollViewer`） | 托管侧新仪器 |
| N6 | **内容绘制计数器** | `PRECOND-CONTENT-DRAW-COUNTER`（现取无此类计数器） | 托管侧新仪器 |
| N7 | **`Hyperlink` 主题色能否当 k=23 的锚** | `NOINFO(依赖主题/系统色，不可从 XAML 复算)` | 一次实测该色的读数（或声明用别的锚） |
| N8 | **色锚的像素保真**（截图链是否保色，例如色彩管理/深度） | `NOINFO(本件只证"空态帧里这些色 0 像素"，未证"真内容帧里必定逐位保色")` | 一次真绘图帧 ＋ C-A 的成对读数 |

---

## §6 ⑥ 载体与边界遵守自证

- **载体**：`build/MilBridge/P1-n4-identity-criteria.md`（新建；UTF-8；模式 **644**；**首记号 `# P1-W62 …`（不是 `# ⏪ `）**；末行自带可复算自报口径）。
- **末行自证口径当场复算**：口径 ＝ `head -n -1 <本件> | sha256sum | cut -c1-16`；**末行所载值 == 当场重算值 ⇒ MATCH**（值见末行）。
- **本件命令的末次执行时刻**：`ts=2026-09-29T14:29:43,616629467+08:00`（`date -Ins` 现取；与 `git status` 同趟）。
- **只读**：命令为 `grep`／`sed`／`awk`／`cat`／`sha256sum`／`stat`／`wc`／`sort`／`uniq`／`find`／`identify`／`command -v` ＋ **只读 python（PIL）** 脚本（落在 `/tmp`）。**零 `dotnet build`、零跑腿、零显示位、零整趟门禁、零 `git` 写。**
- 🔴 **仓外只读**：为取"内容定义的具名色与尺寸"，对**第三方安装**做窄范围只读 `grep`（`~/hc-linux/src/Shared/HandyControlDemo_Shared/UserControl/Styles/{FlowDocumentDemo,RichTextBoxDemo}.xaml`）；**未写入、未运行**。
- **未改任何其它件**：`git status --porcelain` 现取 —— 工作树里的 `??` 全部属他人（`P1-drive-probe-criteria.md`（我上一件）、`P1-guard-tighten-verify.md`、`arm_A/**` 证据），**本件是本次唯一新增件**。
- **引用纪律**：`P1-realized-criteria-report.md`（`281b40613d6f1f34`／214 行）与守卫（`201eca63e6820011`／1068 行）的引用**逐处带 `sha16` 与取值时刻**并标注「本席未独立复算其内读数」；本席**自己复算过**的只有 §0／§1.2 的 `sha16`·行数，以及 §2 全节的像素/工具读数。

---

### 结语（自包含）

- **① 先读判据面**：`N4` 原文（`P1-realized-criteria-report.md` ＝ `281b40613d6f1f34`／214 行，**本席复核与队长所给值相符**）取 **(甲)**＝"登记该页专属期望指纹（帧 `sha256` 或结构读数），条件＝两页各自真绘出内容之后"；守卫的 `PTS_N4_POSITIVE_FP` 现行语义 ＝ **"声明值 == 两腿 `fr_sha` 拼接"** ⇒ 🔴 **它本身不含内容证据 ⇒ 存在"登记即算"的声明式假绿通道**（本件立 C-C 堵它）。
- **② 候选路径（逐条给了可行性/代价/可证伪形态/`NOINFO`）**：(a) **色锚** —— **k=24 活**（`Beige`/`DarkGreen`/`GhostWhite`/`LightGoldenrodYellow` **现取四色全 0 像素** ⇒ 缺席即红、成片即绿；**`LightGray` 是实测出来的死锚**），**k=23 无锚**（该页 XAML 无可自定义色）；(b) **正参照帧不存在**（实测：全仓 275 PNG 中 `1280×1024` 仅 8 枚、全是同一批 4 帧的两份拷贝）⇒ `PRECOND-KNOWN-GOOD-FRAME`；(c) **结构统计**：`ink` 恒真**禁用**、`magenta` 是负身份、`colors` 必要非充分、**行带数四帧全 1 ⇒ 实测死**；只有"**区域限制 ＋ 反极标定**"有希望（区域定义用现算窗口 bbox ＋ 现取导航 rect）；(d) 托管侧：`ENFE=0` 必要非充分、**`[GEO]` 面不含内容区元素（5 个内容侧类型命中全 0）⇒ 当作内容身份死**，需两个新仪器前置；(e) 工具：**无 `tesseract`/`ffmpeg`/`magick`/`gocr`**，有 `compare`/`convert`/`identify`／`PIL 9.0.1`／`numpy 2.2.6`。
- **③ 判据草案**：C-A（色锚，**今天可落地且反极必须红**）／C-B（区域限制 AE，须标定，**不得单独发绿**）／**C-C（登记位加固：登记必须带独立可证伪支撑读数，否则判"声明式登记"）**／C-D（托管侧内容面，两前置今天都不满足）。
- **④ 排期**：**`N4` 今天不是瓶颈**（`N3` 判红 ＋ `N1` 三源不在场 ⇒ 本就不该翻）；`N4` 变成瓶颈的**充要条件**是"两页帧不同 ∧ `N1` 必要件齐 ∧ `N3` 绿"；**准许的下一步** ＝ 把 C-A 落成今天就能跑、**今天必红**的读数，并按 C-C 把要求写进翻转包。
- **⑤ 诚实边界 ＋ 8 条 `NOINFO`/`PRECOND`**（k=23 正身份、正参照帧、登记支撑、阈值标定、内容树 dump、绘制计数器、Hyperlink 主题色、色保真）。
`P1-N4-IDENTITY-CRITERIA 自证（`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ b8ad0a23238156b2（口径＝末行之前的全文；末行＝本行）`

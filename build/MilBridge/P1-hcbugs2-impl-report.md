# `P1` hc 缺陷①**续**：流文档视图「**可见**文字重叠」—— 实现报告（`T-B4`）

- **读时**：`2026-10-02T13:20+0800 … 13:50+0800`（本席现取，各条另注）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=2bffb7f`（现取）。
- **承**：`T-B3`（`build/MilBridge/P1-hcbugs-impl-report.md`）—— 它把①的**段几何**修真
  （`[FSQSPL-DVR] per_para_dvrUsed=[0:33528,1:25146,2:25146] v_rel=[0:0,1:33528,2:58674]`），
  但帧面 `AE=0`、具名 `NOINFO-2`。本件**接着那一条**，把「可见重叠」修到**帧面可证**。
- **件指纹（现取，`sha256` 前 16 位）**：`src/WpfGfx.Linux.Native/src/win32_pts.c edaf0bf17ede9bb9`（改前 `eb0fcd59f21fd746`）｜
  `bin/libwpfwin32.so **5e0d7b807c2fc220**`（`558632 B`；改前 `22e147d144b901c0`）｜
  `bin/exports.txt 83b60726bbc2486e`（`846`，**逐名不变**）｜`tools/pts-gap-decl.txt b076d60a3e179699`｜
  `build/PresentationFramework.Linux/reapply-patches.py 18d8c6e8a1f66a46`｜其重产件 `PtsHelper.Linux.cs d91f6ad43bc561a0`
  （`bin/Release/PresentationFramework.dll a48504540c296366`）。
- **行号纪律**：下文 `win32_pts.c:`／`*.Linux.cs:` 行号**仅本次有效**，一律附**内容锚原文**。
- **副本先行**：写前 `cp -p` 七件到 `~/tb4-work/`（`win32_pts.c.orig`／`exports.txt.orig`／`libwpfwin32.so.orig`／
  `pts-gap-decl.txt.orig`／`reapply-patches.py.orig`／`PtsHelper.Linux.cs.orig`／`TextParaClient.Linux.cs.orig`）。
  **旧 `.so` ＝ `22e147d144b901c0`**（＝`T-B3` 件）：本报告所有「改前」帧/读数即由它现取（同装置同流程）。
- **装置**：`Xvfb :233 -screen 0 1280x1024x24` ＋ `xfwm4 --compositor=off`；demo ＝ `bash ~/run-hc.sh`
  （缺省档、窗口 `800x600@(0,0)`）；点击坐标取 `T-B1` recon §1.2；**重活全走** `~/heavy-slot.sh`；进程只按 PID。
  **首屏对照另跑「不点任何页」腿**（见 §4.3）。

---

## §1 逐跳取证：**几何已真而帧面不变，断在哪一跳**

`T-B3` 的①只落到「段描述符」这一层。本席**先补两处只读判别器**（**改任何行为之前**，见 §2.5）把这条链
逐跳打出来，再动手 —— 判别器本身**不改帧**（§4.3 成对读数）。

| # | 跳（件:行 ＋ 内容锚） | 改前读数（现取） | 判定 |
|---|---|---|---|
| ① | native **段高**出参：`win32_pts.c:9815`（`int hv = wpf_pts_sub_v_extent(obj->child_objs[i]);`）⇒ `[FSQSPL-DVR]` | `per_para_dvrUsed=[0:33528,1:25146,2:25146]` | ✅ **真**（`T-B3`） |
| ② | 托管**累加**：`PtsHelper.Linux.cs:205`（`rcPara.v += dvrPara + dvrTopSpace;`）／`:214`（`dvrPara += arrayParaDesc[index].dvrUsed;`）（上游对位 `PtsHelper.cs:176/180`；⚠️ **改前位形**是 `:204`／`:208`——题面 `T-B4` ①引用的是后者；本件在 `:183` 与 `:207` 插入只读判别器行后**逐条后移 1／6 行**）；读数＝新增判别器 `PtsHelper.Linux.cs:207-211` 的 `[CHAIN] site=PH.ArrangeParaList` | `n=3 idx=0/1/2 parah=0x…8a44/…a284/…bac4 rcPara.v=0/33528/58674` | ✅ **消费了**（几何这一跳没丢） |
| ③ | `_rect = rcPara`：上游 `BaseParaClient.cs:68`（`_rect = rcPara;`）；读数＝`[TPCL] … rectV=`（`TextParaClient.Linux.cs:215`） | 被**渲染**的那 3 段（`…a9664/…aea4/…c6e4`）**不是**②的那 3 段对象 —— 它们走 `n=1` 列表（`rcContent.v=0`）⇒ `rectV=0` | ⚠️ 段矩形**没进到行几何** |
| ④ | **子轨的 `fsrc` 声明**：`win32_pts.c:9599-9601`（`FsQuerySubtrackDetails` 成功支写 `o->u/o->v`）；消费处 `ContainerParaClient.Linux.cs:61`（`FsQuerySubtrackDetails`）→ `:86`（`PtsHelper.ArrangeParaList(PtsContext, subtrackDetails.fsrc, …)`） | `[FSQSTD-SRC] … u=0 **v=0** du=768 dv=576`（**每一条子轨恒定**）⇒ 子段 `rcPara.v = 0 + Σ dvrUsed` **从 0 起** | ❌ **断点之一**：子轨**自己的位置**从未进入子段几何 |
| ⑤ | **行几何**：native `vr_start`。改前 `win32_pts.c:7768`（`rg[i].vr_start = wpf_pts_fl_vr_start(o, i);`；改后同位形 `:7845`，`FSLINEDESCRIPTIONCOMPOSITE` 支 `:7784 → :7862`），其源 `win32_pts.c:7699`（`static int wpf_pts_fl_vr_start(const wpf_pts_subtrack *o, int idx)` **段内自累加**，首行恒 0）；具名 `NOINFO=fsgeometry-layout(vrStart=self-accum)` | `[TPCL] site=RenderSimpleLines.Geom … vrStart=0`（8 行段与两个 6 行段**都**从 0 起） | ❌ **断点之二**：行几何里**没有段在页中的原点** |
| ⑥ | 渲染落位：`TextParaClient.Linux.cs:3332`（`lineVisual.Offset = new Vector(TextDpi.FromTextDpi(lineDesc.urStart), TextDpi.FromTextDpi(lineDesc.vrStart));`，上游 `TextParaClient.cs` 该行**逐字未改**）；段落视觉**不带** offset（`PtsHelper.Linux.cs:306` 只 `visualCollection.Insert(index, paraClient.Visual)`）⇒ 行 `Offset` **就是页坐标** | 3 段 **20 行全从 v=0 起铺** | ⇒ **用户可见重叠** |

**结论（断点＝④⑤）**：`T-B3` 修好的 `rcPara.v` **只到"段落矩形"这一层**（背景/边框/命中测试/`Figure` 锚用），
**不流向任何行几何**；行几何的**唯一来源**是 native `vr_start`，而它（连同它依存的子轨 `fsrc.v`）
缺的正是"**这一段在页中的原点**"。⇒ 只把「同 track 各段的行盒 `v`」错开还不够，必须让
**子轨原点（④）**与**行 `vr_start`（⑤）**都带上页绝对 `v`。

**④⑤ 的同一个真值**（本件自算，规则**逐字照抄宿主**）：`段绝对 v = Σ_祖先 [ (该层子轨 `fsrc.v` 声明) + Σ_{k<idx}(extent(前兄弟 k)) ]`，
其中 `extent` ＝ `wpf_pts_sub_v_extent`（**同一函数**＝宿主拿到的那条 `dvrUsed`）、 `fsrc.v` 本侧声明
**逐层为 0**（④ 改前）⇒ 化简为「沿 `parent` 链累加前兄弟段高」。⇒ **本件＝把宿主那条 `rcPara.v` 规则在 native 侧复算一次**，
使 ①—⑥ 六跳**同一个数**（见 §3 表的 `rcContent.v` 与 `vrStart` 逐段相等）。

---

## §2 改动（逐处：件:行 ＋ 原文 ＋ 作者性）

落点全在**允许清单**内：`src/WpfGfx.Linux.Native/src/win32_pts.c`（源件直改）
＋ 生成器 `build/PresentationFramework.Linux/reapply-patches.py`（`P8`：**生成件只经生成器**）及其重产件。

### 2.1 父子边（绝对 `v` 的链）

`wpf_pts_subtrack_s` 新增 `struct wpf_pts_subtrack_s *parent; int idx_in_parent;`（`win32_pts.c:1651-1652`，
内容锚 `struct wpf_pts_subtrack_s *parent;`）；`wpf_pts_sub_new` 里缺省 `parent=NULL; idx_in_parent=-1;`
（`win32_pts.c:1741`）；建树处 `wpf_pts_sub_enum_into` 写 `co->parent = obj; co->idx_in_parent = k;`（`win32_pts.c:2350-2351`）。

🔴 **一处易漏的边**：顶层三个子段对象是 `wpf_pts_sub_enum` 里**先建、后由 `FsQueryTrackParaList`
过继给 `dp->sub`** 的（`win32_pts.c:9269-9278`：`dp->sub->child_objs[k] = dp->sub_child_objs[k];`
＋ `dp->sub->child_objs[k]->parent = dp->sub;`）
—— 过继时**必须补 `parent/idx`**，否则链断在这一层（本席首版即断在此：`[FSQSPL-ABSV] … abs_v=[0:0,1:0,2:0]`）。

### 2.2 子轨原点：`FSSUBTRACKDETAILS.fsrc.v`

`win32_pts.c:9599-9606`（内容锚 `int av = obj->in_subpage ? 0 : wpf_pts_sub_abs_v(obj);` ／ `o->v = (av >= 0) ? av : 0;`）。
上游语义（`Pts.cs:1527-1533`）`FSSUBTRACKDETAILS.fsrc` ＝ **该子轨的矩形（页坐标）**；本侧原恒 `u=v=0`。
`dvr_shifted/fskupd/nms/du/dv` 一格未动（`du/dv` 仍是本侧声明几何，具名照旧）。

- **零假值**：`wpf_pts_sub_abs_v` 取不到（链上任一跳段高不可用／父未造型／成环）⇒ 返 `-1`
  ⇒ **保持 0** 并具名 `absv=NOINFO(chain-short)`；**绝不**用 0/常数冒充。
- **子页内容树**（`in_subpage`）坐标系**以子页为原点**（`Figure`/`Floater` 内容视觉带 `ContentRect` offset）
  ⇒ 该支**逐字保持 0** 并具名 `absv=SUBPAGE-LOCAL(0)`（现取 90+90+30+30+30 条，见 `[FSQSTD-SRC]`）。

### 2.3 行几何：`vr_start` ＝ 页绝对 `v` ＋ 段内累加

- `win32_pts.c:7822-7830`（内容锚 `static int wpf_pts_line_v_base(const wpf_pts_subtrack *o)`）：`vbase` ＝
  `in_subpage ? 0 : wpf_pts_sub_abs_v(o)`；
- `win32_pts.c:7845`（`FSLINEDESCRIPTIONSINGLE`）与 `win32_pts.c:7862`（`FSLINEDESCRIPTIONCOMPOSITE`；**改前**位形
  `:7768`／`:7784`）：
  改前 `vr_start = wpf_pts_fl_vr_start(o, i);` ⇒ 改后 `vr_start = vbase + wpf_pts_fl_vr_start(o, i);`。
- `ur_start`／`dur`／`ur_bbox`／`ascent/descent` **一格未动**（u 方向本侧无真源，具名照旧）；`FSLINEELEMENT`
  亦未动（其 v 由宿主从 `lineDesc.vrStart` 带入，同一真值）。

### 2.4 反极性闸（本件新增，供 §4 成对腿）

`WPF_PTS_LINE_ABS_V`（`win32_pts.c:7763-7773`，内容锚 `static int wpf_pts_line_absv_on(void)`）：
**缺省 `1`**＝本增量生效；**只有**显式 `0` ⇒ 逐字回**改前**行为（`vr_start` 自累加 ＋ `fsrc.v` 恒 0，
退路写点 `win32_pts.c:9605` ／ `win32_pts.c:7825`）。
读数落在 `[FSQSTD-SRC]` 的 `absv=`／`gate=` 与 `line_rev=`。

### 2.5 只读判别器（**新增，先于改行为落地**）

1. **native** `[FSQSPL-ABSV]`（`win32_pts.c:9878-9899`，内容锚 `char chbuf[WPF_PTS_SUB_CHILD_MAX * 24 + 1];`
   ／ `fprintf(stderr, "[FSQSPL-ABSV] psub=%p cParas=%d ch=[%s] abs_v=[%s] ph=%p idx=%d "`）：逐子轨打印**本侧句柄序** `ch=[…]` 与
   本侧自算的 `abs_v=[…]` —— 把「哪个父轨交出了被渲染的那几段」**直接对上**
   （`[TPCL] parah=`／`[CHAIN] PH.ArrangeParaList parah=` 是同一枚值）；`[SUBTREE]` 加 `sub=/ch0..ch2=`。
2. **托管** `[CHAIN] site=PH.ArrangeParaList`（生成器 `reapply-patches.py` 的 `PtsHelper.cs` 编辑项，
   重产件 `PtsHelper.Linux.cs:183`（入口行）／`:207-211`（逐段 `rcPara.v`））：把**宿主真算出来的**
   `rcPara.v` 落行 —— 这一跳改前**本侧无读数**，正是 `T-B3` 只能报几何的原因。
   `WPF_CHAIN_PROBE=0` ⇒ 整块不发生（逐字回上游行为）。

### 2.6 未选的两条路（如实记账，均已否决）

- **乙 · 托管侧贴膏药**（`lineVisual.Offset = (urStart, _rect.v + vrStart)`，走生成器）：能出画面，
  但把 native 的 0 几何在托管侧**再补一次**，与「几何须可辩护、可复算」相悖，且与 `_rect` 的**两代对象**
  事实纠缠（§1-③）；**不选**。
- **丙 · `Figure`/`Floater` 绕排**（让正文行避让浮动盒）：那要**行断器**知道浮动几何（真 PTS 的
  `fClearOnLeft/Right` ＋ 变宽行盒），本侧 `pfnFormatLine` 现以 `0,du,0,du`（`win32_pts.c:2544` 附近）驱动
  ⇒ **不是本增量射程**，见 §6-① 具名残留。

---

## §3 帧面成对（同一装置、同一流程、只差一个件）

| 面 | 改前（`so 22e147d144b901c0`） | 改后（`so 5e0d7b807c2fc220`） |
|---|---|---|
| 帧 `sha16`（tab1 全屏） | `cb7567c5162b5daa` | **`e191e3b80fa75c42`** |
| **AE**（本席现取，全屏 1280×1024） | — | **`27097 px`**（逐通道\|Δ\|合计 `>30`；任一通道有差 `30276 px`） |
| AE 的**空间范围** | — | `bbox=(303,147)-(747,436)`＝**只有文档文本列**（左导航 `x<250`／窗口边框**逐像素相同**） |
| ① 同 track 逐段 `rcPara.v`（宿主侧新读数） | `n=3: 0/33528/58674`（真）；被渲染那代 `n=1: rcContent.v=0` | `n=1: rcContent.v=33528/58674`；`n=3` 同前 |
| ① 子轨 `fsrc`（`[FSQSTD-SRC]`） | 叶容器 `u=0 v=0`（`absv` 字段本波才有） | 叶容器 `u=0 **v=33528/58674**`（`absv=PAGE-ABS`）；根 `v=0`；子页 `SUBPAGE-LOCAL(0)` |
| ① 行几何 `[TPCL] site=RenderSimpleLines.Geom` | 8 行段／两个 6 行段 **`vrStart=0`** | 8 行段 **`0`**、6 行段 **`33528`**、6 行段 **`58674`**（与 `_rect.v` 逐段相等） |
| 帧面「文本墨迹**垂直跨度**」（文档正文区 `x=250..780`） | `y=147..261`＝**`115 px`** | `y=147..436`＝**`290 px`** |
| 帧面**行带**（暗行被全空行隔开） | **`1`** 带（`147..261`），带内**全空行 `0`** | **`8`** 带（`147..261｜263..276｜278..305｜307..334｜336..363｜365..392｜394..407｜409..436`），带内**全空行 `7`** |
| 帧面**行槽**墨迹（以首墨行起点、按 native 行距 `13.97 px` 分 20 槽） | `[972,981,714,1399,1447,1279,751,234,`**`0×12`**`]` ⇒ **12 个槽零墨** | `[493,666,364,777,843,688,744,234,784,801,921,841,906,756,763,630,797,869,949,919]` ⇒ **20 槽全有墨** |
| 帧面文本墨迹**总量**（暗像素，`sum(RGB)<400`） | `7780` | `15472` |
| **重叠量**（＝`1 − 实测跨度 / (20 行 × 13.97 px = 279.4 px)`） | **`58.8 %`**（115/279.4） | **`0`**（290/279.4 ⇒ 量测粒度内） |

**「同一 `x` 列上两行文本带 `y` 区间不再相交」（题面判据）的现取形态**：
改前 3 段 20 行**共 `v`** ⇒ 文本带 `147..261` 内**无一行全空**（相邻行 `y` 区间 100 % 相交）、
20 个行槽**只有 8 个**含墨（`v_rel` 全是 0）；改后 20 行**各占自己的槽**（每槽 1 行的墨量）、
8 条行带被 **7 条全空行**隔开 ⇒ **相交量 = 0**。

> 行距 `13.97 px` 的**来源**＝native 行台账（`[FORMATLINE-LINE] ascent=3342 descent=849` ⇒ `4191 TextDpi`／`300`）。
> 帧面 `1 px = 1 DIP`（窗口 `800x600`，`xdotool getwindowgeometry` 现取）⇒ 二者可直接换算（**不是**拿几何冒充帧面）。

---

## §4 反极性 ＋ 无附带影响（成对）

### 4.1 撤该修 ⇒ 回**原帧**（逐像素）

同一 `.so`（`5e0d7b807c2fc220`），只差 `WPF_PTS_LINE_ABS_V=0`：

| 腿 | 日志 | 帧 `sha16` | AE（vs 改前帧） |
|---|---|---|---|
| 正腿（缺省，闸＝1） | `/tmp/hc-run-133859.log`（`fix2`） | `e191e3b80fa75c42` | 27097 px |
| **反腿**（`WPF_PTS_LINE_ABS_V=0`） | `/tmp/hc-run-133920.log`（`rev`）／`/tmp/hc-run-134125.log`（`rev3`） | **`cb7567c5162b5daa`** | **`0 px`**（逐像素相同） |

反腿日志同时具名：`[FSQSTD-SRC] … u=0 v=0 … absv=REVERSE-LEG(0) gate=0 … line_rev=6/11/12`、
`[CHAIN] PH.ArrangeParaList n=1 idx=0 … rcContent.v=0 … rcPara.v=0`、`[TPCL] … vrStart=0`。
⇒ **同一份件、只差一个环境变量，帧面「改前↔改后」双向成立**（不是"活/不活"，是**逐像素**）。

### 4.2 首版（无闸）↔ 加闸版 ↔ 三趟复跑：**同帧**

`fix1`（`.so 558496 B`，无闸）／`fix2`（`5e0d7b807c2fc220`，有闸）／`fix3`（同一件，三页签流程）
⇒ 帧 `sha16` **`e191e3b80fa75c42` 逐字相同**（`~/tb4-work/{fix1,fix2,fix3}-tab1.png`）；
`rev`／`rev3`／`base` 亦然（`cb7567c5162b5daa`）。⇒ 本增量**可复现**且**判别器只读**
（`base`／`probe`／`absv` 三趟：`.so 22e147d144b901c0`＋无判别器／有判别器／有父子边日志 ⇒ 帧**全同**）。

### 4.3 无附带影响（非 PTS 页）

**不点任何页**（首页缺省态）的帧：`.so 22e147d144b901c0` 与 `5e0d7b807c2fc220` **两腿同帧**
`b21eb530afd3c66c`（`~/tb4-work/{homebase,homefix}-home.png`）⇒ 本增量**不改变**首页；
`tab1` 帧的差异 `bbox` 又**只在文档文本列内**（§3）⇒ **改动是外科式的**。

---

## §5 验收（逐条）

1. **① 逐跳证据（哪一跳没消费几何）＋件:行**：§1 表（六跳；**④⑤** 是断点；
   `[CHAIN] PH.ArrangeParaList`／`[FSQSPL-ABSV]`／`[FSQSTD-SRC]` 三条读数行 ＋ 生成件/上游行锚）。✓
2. **② 帧面成对（帧 `sha16` 前后 ＋ `AE`）＋ 重叠量前后对照（数值）**：§3 表
   （`cb7567c5162b5daa → e191e3b80fa75c42`；`AE=27097 px`；重叠量 `58.8 % → 0`；行槽 `12 槽零墨 → 0`；
   行带 `1 → 8`；跨度 `115 → 290 px`）。✓
3. **③ 反极性（撤该修 ⇒ 回原帧）**：§4.1（**`AE=0 px`，逐像素**）。✓
4. **④ 门**：`nm -D --defined-only` ＝ `bin/exports.txt` ＝ **`846`** 逐名相等（`diff -q` 空）✓｜
   **`PTSGAP=PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=5e0d7b807c2fc220 exports=846`** ✓
   （`pts-gap-decl.txt` 的 `PTSGAP-DECL` 行 `so16` 重锚；`PTSGAP_FRONTIER_STATE=NAMED`）｜
   **`DEFREG=PASS declared=225 route_ids=225`**（rc=0）｜**`REPORTID=PASS`**（rc=0，见 §7 尾注现取数）。
5. **⑤ 不得回退**：`PTS_GUARD=PASS legs=2/2`（`bash build/MilBridge/tools/pts-pages-guard.sh --legs build/MilBridge/tests/PtsPagesProbe/evidence`，rc=0）｜
   `PTS_COLORANCHOR=PASS k=24 … hits=3`（同趟）。✓
6. **⑥ 症状门成对**（现取，全屏；同一装置同流程）：

   | 症状门 | 改前（`22e147d144b901c0`） | 改后（`5e0d7b807c2fc220`） | 反腿（同一件、闸 0） |
   |---|---|---|---|
   | `magenta` | `0` | `0` | `0` |
   | 具名色计数（`GhostWhite/Beige/DarkGreen/LGY`） | `9794/910/44/5830`（`hits=3`） | `9813/910/44/5830`（`hits=3`） | **逐字相同**（`9794/910/44/5830`） |
   | `ink`（暗像素，全屏） | `868527` | `877479` | `868527` |
   | `colors`（不同 RGB 数，全屏） | `1219` | `1172` | `1219` |
   | `alive`／`app_rc` | `yes`／`143`（本席按 PID 收） | `yes`／`143` | `yes`／`143` |
   | `Unrecoverable`／`Handle has been already released`／`Process terminated` | `0` | `0` | `0` |
   | `PtsException`／`HC-UNHANDLED`（**三页签趟**：`rev3`＝反腿＝同件闸 0，即"改前"；`fix3`＝改后） | `3`／`3`（`rev3`） | `3`／`3`（`fix3`） | `3`／`3`（`rev3`） |
   | ② 拒发（`stale-paraclient-across-page-destroy`） | **`1`** 次（`rev3`：`[FS_PAGE_GAP] rc=-10000`） | **`1`** 次（`fix3`，`T-B3` 收严仍在） | `1` 次 |

7. **附（本席另跑，非题面要求，不许当绿）**：`build-shim.sh --abi` ⇒ **ABI 布局自检全一致**
   （`_Static_assert` 亦过；本增量的 `parent/idx_in_parent` 是**内部结构**、不在 ABI 面）；
   三支 native 自检（现取，`fix2` 日志）`[FSPARALIST-SUB-SELFTEST]`／`[PROV-SELFTEST]`／`[SUBTREE-SELFTEST]`
   三行**皆** `mask=0x1f`（`5/5`）**未回退**；
   `sync-applocal.sh --check` ⇒ `SYNC-APPLOCAL=PASS items=5 ok=5 drift=0`（应用目录五件＝仓内权威）。

---

## §6 具名 `NOINFO` 与边界（如实划界）

1. **`NOINFO-1`（缺陷①的**残留**可见重叠：`Figure`/`Floater` **绕排**未实现）**：
   改后帧里 `Figure`（`Beige`，`bbox=[422,161,517,174]`）与 `Floater`（`GhostWhite bbox=[415,153,747,242]`／
   `LightGoldenrodYellow [526,181,747,234]`）的**位置逐像素未变**，而它们**锚在段 0**（`Paragraph` 的 inline `Figure`/`Floater`）
   ⇒ 这两个盒的**内容行**与段 0 的**正文行**仍共 `y`。**这是另一条机制**（行断器不知道浮动几何：
   `pfnFormatLine` 现以 `0,du,0,du` 驱动、`fClearOnLeft/Right=0`），**本增量未声称修好**
   ⇒ 该腿记 **`NOINFO=float-avoidance-not-implemented`**（题面「重叠量前后对照」一栏的所有数值**只**对
   「同 track 各段的行盒」成立）。
2. **`NOINFO-2`（`tab2`/`tab3` 帧未变）**：`tb4-work/{fix3,rev3}-tab2.png`＝`12db11a7c39acaa0`、
   `-tab3.png`＝`40dbbd1703f3e360`，与改前**同值** ⇒ 本装置上那两页**不绘文档内容**
   （与 `T-B3` 的 `NOINFO-2` 同族，本轮**未**另立判据）。
3. **`NOINFO-3`（`dvrTopSpace`）**：本侧**无几何源** ⇒ 恒 0 并具名（`[FSQSPL]` 的
   `NOINFO=dvrTopSpace/bbox=0(no-top-space-source,no-bbox-source)`；`[FSQSTD-SRC]` 的 `du/dv` 仍是声明几何）。
4. **`NOINFO-4`（u 方向）**：`ur_start` 仍＝`ur_bbox`（本侧无真源）⇒ 本次**只**修 `v`；题面「同一 `x` 列」
   的现取形态是按 `v` 维（行带/行槽）判的，**不**声称 `u` 几何真。
5. **未跑**：整趟 `verify-all`（照 `T-B3` ②）、`static-jaws-check.sh`。
6. **黑名单未碰**：`build/MilBridge/tools/**`（判据件，只**调**不**改**）／`verify-all.sh`／`build/close-wave.sh`／
   `build/shims/**`／`upstream/**`（**只读**，`upstream` 的 `BaseParaClient.cs`／`PtsHelper.cs`／`TextParaClient.cs`
   逐字未动）／hc demo 仓外工程 —— 逐处均未写（`git status` 现取只有 §7 五个件 ＋ 本报告）。
7. **装置纪律**：显示位只用 **`:233`**（未占 `:10`）；所有 demo 进程**只按 PID** 收（`pgrep -f 'Handy[C]ontrolDemo.dll'`
   ＋ `kill`），退出码 `143` 即本席所杀；重活全走 `~/heavy-slot.sh`（`--min-avail 2500 --max-hold 600 --wait 300`）。
   ⚠️ **现取遗留（如实登记）**：`:233` 的 `Xvfb`／`xfwm4` **两个进程本席未收**（PID 记在 `~/tb4-work/{xvfb,wm}.pid`；
   台账现取无遗留 `HandyControlDemo` 进程）⇒ 下一位可直接复用该显示位；要收按 PID 收。

---

## §7 改动清单（逐文件）

| 件 | 改什么 |
|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | §2.1 父子边（结构 ＋ 建树 ＋ **过继处补边**）／§2.2 `fsrc.v`／§2.3 行 `vr_start`／§2.4 反极性闸／§2.5 两处只读判别器（`[FSQSPL-ABSV]`／`[SUBTREE]` 加格）。**未动**任何既有反腿旋钮的语义；`u` 方向逐字未动 |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | **构建重产**（`22e147d144b901c0 → 5e0d7b807c2fc220`；`558632 B`；两次独立构建同 `sha16` ⇒ 可复现） |
| `src/WpfGfx.Linux.Native/bin/exports.txt` | **构建重产**（`nm -D --defined-only`，**逐名不变**，`846`） |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `PTSGAP-DECL` 行的 `so16:` 重锚（**只此一格**；`tool/dead/artifact/ops/impl/exports/w66pre16` 未动） |
| `build/PresentationFramework.Linux/reapply-patches.py` | §2.5-2：`PtsHelper.cs` 编辑项加两处只读 `[CHAIN]` 行（入口 ＋ 逐段 `rcPara.v`） |
| `build/PresentationFramework.Linux/PtsHelper.Linux.cs` | 生成器**重产件**（`7` 处改动，`needle` 全部命中；新 `sha16 d91f6ad43bc561a0`） |
| `docs/unimplemented.md` | `D-G70` **现值位**的 `so16` 随动（历史 `dated` 行**一字未动**） |
| `build/MilBridge/P1-hcbugs2-impl-report.md` | **新建**（本报告） |

**未改（有意）**：`docs/ROUTES.md`／`README.md` 里的 `so16=22e147d144b901c0` 全在 **`dated` 历史段**
（本仓「只增不改」纪律）⇒ 保留原文；`PTSGAP` 牙现取 `PASS`（它不抽历史行的 `so16`）。
**门现取（写本件之后重跑）**：`DEFREG=PASS declared=225 route_ids=225`（rc=0）｜
`REPORTID=PASS files=353 ids=2265 declared=225`（rc=0）｜`PTSGAP=PASS … so16=5e0d7b807c2fc220 exports=846`。

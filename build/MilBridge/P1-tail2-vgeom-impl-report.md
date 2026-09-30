# `P1-tail2` · `T-A42` · native 内容段入站几何自洽（`NATIVE-PTS-CONTENT-VIEWPORT-V-SELFREF`）—— 实现报告（**判决：几何已落 ∧ 前提被证伪 ∧ 判据 ② 未达**）

- **读时**：`2026-09-30T19:0x+0800`（本席现取，各条另注）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=ddc1a5ef57a05219ae49da739fdb2ff00ba960b7`（现取，**未换代**）。
- **改前件备份（仓外 `~/tA42-work/bak/`，`cp -p` 取在**任何写之前**）**：`win32_pts.c.bak`（**`af6d534194bccd76`**）／`libwpfwin32.so.bak`（**`dd9865c38e18ed81`**）／`exports.txt.bak`（**`860a3abe4a64f1c5`**，683 行）／`pts-gap-decl.txt.bak`（**`78c820e26925cd75`**）。
- **只改**：`src/WpfGfx.Linux.Native/src/win32_pts.c`（内容段入站几何自洽，**一处函数**）／**随动** `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（`so16` 重锚）／**复述位** `build/MilBridge/HANDOFF-NEXT.md`（`§3` 追加一条 `T-A42` dated 行）／**新建**证据目录 `build/MilBridge/tests/PtsPagesProbe/evidence-tail2i/`（`legA`／`legB`／`legC` 三腿）／本载体。
- **未改**（如实划界）：`bin/exports.txt`（`cmp` 逐字节未变）、`build/*.Linux/**`（生成件）、`build/shims/**`、`verify-all.sh`、`build/close-wave.sh`、`build/MilBridge/tools/**`（**只读跑**判据件）、`docs/ROUTES.md`／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`src/WpfGfx.Linux.Native/src/win32_classification.c`（见 §5-5 的**机器证**）；**未跑**整趟 `verify-all`；**未跑** `static-jaws-check.sh`；未改相位；未 `git add/commit/push`。
- **重活**：**2 趟 native 构建**（末一趟为最终产物）＋ **1 趟跑器**（3 腿，逐腿 `HEAVYSLOT=ACQUIRED/MEMOK/RELEASED` 可见；`held=102s`）全走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- <cmd>`；进程只按 PID；显示位 `:231`（装置自取；三腿逐腿 `DEVICE_REAP state=clean`）；禁 `sleep` 轮询；写前 `cp -p` 备份；模式守恒。
- **口径**：一切读数**本席现取**（`sha256sum`／`nm`／`grep -c`／只读 `python3`＋`PIL` 解 PNG／`bash build/MilBridge/tools/{pts-pages-guard,pts-gap-count-check,defect-registry-check,report-id-domain-check}.sh`）；`P1-tail2-fsview-impl-report.md`（`T-A41`）／`P1-tail2-subgeom-impl-report.md`（`T-A39`）／`P1-tail2-visual-recon.md`（`T-A40`）**只作对照**，其读数**一条未抄**。
- **行号纪律**：本件行号**仅本次有效**；引件一律给**内容锚**。

---

## §0 结论速览（自包含）

1. ✅ **几何改动已落且可复算**：附属对象页矩形锚的 `v` 由 `20000 + (idx/4)*40000` 改为**页面 v 原点 `0`**（缺省）⇒ 托管 `viewportSubpage.v = viewport.v − ContentRect.v = viewport.v`，即 `viewport.v` 与 `ContentRect.v` **同一参照**。**算式与单位见 §1.1**。**同一产物**上两极可切：`WPF_PTS_ATT_VSELF=0`（回原值 `20000`）／`=f`（远锚 `200000`）。
2. ✅ **几何真进渲染面（三腿成对可分）**：`[FS_ATT] FsQueryFigureObjectDetails` 现取 `fsrc.v` ＝ **`0`／`20000`／`200000`** 逐腿；`k24` 帧 ＝ **`2d89d393157b0df6`／`1487caf78fd88886`／`fa7df9222ebb199f`**；`GhostWhite` ＝ **`29667`／`29637`／`0` px**（远锚腿把附属对象挪出页 ⇒ **背景也消失**）。⇒ 本改动**不是空转**；且 `legB` 的 `k24` 帧与改前（`T-A36`／`T-A37`／`T-A39`／`T-A41` 在册 `1487caf78fd88886`）**逐字节相同**（**强反极**）。
3. 🔴 **判据 ② 未达，且本件前提（`T-A41` 的真断点）被证伪**：三腿 `[FSQLL] cLines=1` **恒 0**、`PTS_COLORANCHOR hits = 1／1／0`（`Beige`／`DarkGreen`／`LightGoldenrodYellow` **恒 0 px**）。关键读数是**门的真／假两极**：`legA`／`legB` **门真**、`legC` **门假**，**两支结果相同**（内容像素恒 0）⇒ **`TextParaClient.IntersectsWithRectOnV` 这一门不是断点**（与 `T-A39` 的"门必真探针"**同向**）。⇒ `T-A41` 指认的靶（"开门需视口伸到 ≈6400 DIP"）**不成立**。
4. ✅ **单位更正（可复算，`D-G125` 同族）**：`MS.Internal.Text.TextDpi` 的 `_scale = 28800.0/96 = 300` ⇒ **1 DIP = 300 文本单位**；故 `ContentRect.v = 20000` 文本 ＝ **`66.67` DIP**（**不是** `T-A41` 写的 `≈6400 DIP`；`6400` 对应的换算是 `÷3.125`，与 `_scale` 不符）。**该更正不改变判决**：即便按 `66.67` DIP，`viewport.v = 0` 且 `viewport.dv = 366.72 DIP` ⇒ 门**本来就真**（§1.1）。
5. ✅ **症状门零回归**：三腿 `alive=yes app_rc=143 failfast=0 unrec=0 magenta=0 ink=480000 ns=…FlowDocumentDemo`、`[HC-UNHANDLED]=1`（**未涨**）、`entry point named=0`；`boot.png` 三腿同值 `b21eb530afd3c66c`（四色仍全 0）、`k23` 三腿同值 `10d0b9d54e649c10`。
6. ✅ **门禁（④）**：`nm -D --defined-only` ＝ `exports.txt` ＝ **683**（逐名 `diff` 零差异，**无导出增删**）；`PTSGAP=PASS tool=76 dead=11 artifact=1 ops=64 impl=67 so16=5b7d0ac101673900 exports=683`（rc=0）；`DEFREG=PASS declared=225 route_ids=225`（rc=0）；`REPORTID=PASS files=322 ids=2233 declared=225`（rc=0；件数 `321 → 322` ＝ 本载体）。
7. 🔴 **下一靶（具名，本件只给读数与两件可复算仪器）**：**内容段的两支"造行视觉"都没被托管调用**（`[FSQLL] cLines=1` 恒 0，而内容段 `[FSQTD] cLines=1` 三腿＝`166／336／170` ⇒ **查询支到、造行支不到**）⇒ 靶在**渲染面**（"内容段的视觉支为什么没被调"），**不在 native 几何**。

---

## §1 改动（逐处）

### 1.1 内容段入站几何自洽（`win32_pts.c`，**一处函数 ＋ 一个页锚取数口**）

**算式（四行都逐字取自上/下游，可复算）**：
| # | 托管/native 式 | 内容锚（原文） |
|---|---|---|
| ① | `_contentRect.v = _rect.v + mbp.BPTop`，`_rect = fsrcFlowAround` | `FigureParaClient.OnArrange`（`FigureParaClient.cs`：「`_rect = rcFigure;`」→「`_contentRect.v = _rect.v + mbp.BPTop;`」） |
| ② | `fsrcFlowAround` ＝ **本侧** `FsQueryFigureObjectDetails` 的 `fsrc_flow_around` | 本件 §1.1 改的即是它的 `v`（`d->fsrc_flow_around = rc;`，`rc` 来自 `wpf_pts_att_geometry`） |
| ③ | `viewportSubpage.v = viewport.v − ContentRect.v` | `FigureParaClient.UpdateViewport`（「`v = viewport.v - ContentRect.v,`」） |
| ④ | 门：`(_rect.v ≤ vp.v + vp.dv) ∧ (_rect.v + _rect.dv ≥ vp.v)`，`vp := viewportSubpage` | `TextParaClient.IntersectsWithRectOnV`（「`return ((_rect.v) <= (rect.v + rect.dv)) && ((_rect.v + _rect.dv) >= rect.v);`」） |

**内容段 `_rect.v` 的来源**：`PtsHelper.ArrangeParaList(ptsContext, rcTrackContent, …)`（`rcPara.v = rcTrackContent.v + dvrPara + dvrTopSpace`），而 `rcTrackContent` ＝ **子页轨 `fsrc`**（本侧 `FsQuerySubpageDetails` 声明 `fsrc=(0,0,37810,10810)`）⇒ `_rect.v = 0`（**现取** `[FS_ATT] … FsQuerySubpageDetails … fsrc=(0,0,37810,10810)`）。

**单位（现取自上游）**：`TextDpi._scale = 28800.0/96;` ⇒ **1 DIP = 300 文本单位**。托管视口（`[FSVIEW]` 现取）＝ `viewport=(0,0,638.4,366.72)` **DIP** ＝ `(0,0,191520,110016)` **文本**。

**两极的算式（门值可算）**：
- **改前／反极 `v=20000`**：`ContentRect.v = 20000` 文本；`viewportSubpage.v = 0 − 20000 = −20000`；门：`0 ≤ −20000 + 110016 = 90016` **真** ∧ `0 ≥ −20000` **真** ⇒ **门真**。
- **自洽 `v=0`（缺省）**：`ContentRect.v = BPTop = 0`（`Figure`/`Floater` 无 Border/Padding）；`viewportSubpage.v = viewport.v`；门：`0 ≤ 110016` **真** ∧ `0 ≥ 0` **真** ⇒ **门真**（**门值未变**）。
- **远锚 `v=200000`**：`ContentRect.v = 200000` 文本；`viewportSubpage.v = −200000`；门：`0 ≤ −200000 + 110016 < 0` ⇒ **假**。

⇒ **改动本身只把两个操作数搬到同一参照，门的取值从"真"仍是"真"** —— 这正是本件用来**反演"门是不是断点"**的两个自变量（§4）。

**代码（`win32_pts.c`，改前 → 改后；`numstat 18 1`）**：
```c
/* ── 缺省（自洽）：页面 v 原点 ⇒ viewportSubpage.v = viewport.v ── */
static int wpf_pts_att_page_anchor_v(int idx)
{
    const char *s = getenv("WPF_PTS_ATT_VSELF");
    if (s && s[0] == '0') return 20000 + (idx / 4) * 40000;   /* 反极：原值 */
    if (s && s[0] == 'f') return 200000;                      /* 远锚：门**必假** */
    return 0;                                                 /* 自洽（缺省） */
}
static void wpf_pts_att_geometry(int idx, int is_figure, wpf_pts_fsrect *out)
{
    out->du = is_figure ? WPF_PTS_ATT_FIG_DU : WPF_PTS_ATT_FLO_DU;
    out->dv = is_figure ? WPF_PTS_ATT_FIG_DV : WPF_PTS_ATT_FLO_DV;
    out->u  = 30000 + (idx % 4) * 30000;
    out->v  = wpf_pts_att_page_anchor_v(idx);                 /* 原：out->v = 20000 + (idx/4)*40000; */
}
```
- **只动一个入参面**：`out->u`／`out->du`／`out->dv` **一字未动**（⇒ `ContentRect` 的 u／尺寸维持原约定，`GhostWhite` 背景宽度可作旁证：三腿 `29667／29637` 同量级）。
- **零新增导出、零 `wpf_pts_gap(...)` 增删** ⇒ `exports`／`tool/dead/artifact/ops/impl` **逐格未动**（§2.3 机器证）。
- **反极性不靠第二次构建**：三态在同一 `.so` 上由 `WPF_PTS_ATT_VSELF` 切（承 `T-A41` 的 `WPF_FSVIEW_VIEWPORT_DRIVE` 形态）。

### 1.2 逐件 sha16 ＋ `numstat`（现取）
| 件 | 改前 | 改后 | `numstat` |
|---|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `af6d534194bccd76` | **`826c896ebe77e917`** | `18 1` |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so`（构建生成件） | `dd9865c38e18ed81` | **`5b7d0ac101673900`**（449248→449432 B） | —— |
| `src/WpfGfx.Linux.Native/bin/exports.txt`（构建生成件） | 683 行／`860a3abe4a64f1c5` | **683 行／`860a3abe4a64f1c5`**（`cmp` 未变） | —— |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `78c820e26925cd75` | **`995009570c490baa`** | `14 1` |
| `build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` | `52cf1b0012667dd0` | **`52cf1b0012667dd0`**（**托管面零改动**，未重建） | —— |

**构建（现取）**：`bash build-shim.sh --symbols` ⇒ `rc=0`；`-W*` 警告**逐条为既有**（`win32_misc.c:224`／`win32_pts.c:1718` `dA0`／`win32_pts.c:2010` `wpf_pts_fsp_pl_is_sentinel`），本增量**不新增**警告。**未重建托管**（几何全在 native；`pf` 逐字节未变 ⇒ `sync-applocal` 只刷 `.so` 一件）。

---

## §2 成对读数（**同一装置 `:231`／同一产物 `5b7d0ac101673900`／同批工具**：`runner_sha16=330a90f1f0ac28e4`／`session_sha16=f1a582d9ea9788c9`／`guard_sha16=962fec114b2d0692`；A 臂 `clicks=[24,23]`；证据 `build/MilBridge/tests/PtsPagesProbe/evidence-tail2i/`）

| 腿 | `WPF_PTS_ATT_VSELF` | 附属对象 `fsrc.v` | 门（算得） | `k24` `fr_sha` | 证据目录 |
|---|---|---|---|---|---|
| `legA`（**自洽**） | **unset** | `0` | **真** | **`2d89d393157b0df6`** | `…/evidence-tail2i/legA/` |
| `legB`（**反极 · 原值**） | **`0`** | `20000` | **真** | **`1487caf78fd88886`** | `…/evidence-tail2i/legB/` |
| `legC`（**远锚 · 门必假**） | **`f`** | `200000` | **假** | **`fa7df9222ebb199f`** | `…/evidence-tail2i/legC/` |

### 2.1 帧面四色锚（本席自算，只读 PNG；锚集＝`GhostWhite=248,248,255`／`Beige=245,245,220`／`DarkGreen=0,100,0`／`LightGoldenrodYellow=250,250,210`；`min=200`，**`hits>=2` 才绿**）
| 腿 | 帧 | `GhostWhite` | `Beige` | `DarkGreen` | `LightGoldenrodYellow` | `hits(≥200px)` | `bbox(GhostWhite)` |
|---|---|---|---|---|---|---|---|
| `legA` | `k24` | **29667** | **0** | **0** | **0** | **1** | `(415,153)-(747,242)` |
| `legB` | `k24` | **29637** | **0** | **0** | **0** | **1** | `(415,223)-(747,311)` |
| `legC` | `k24` | **0** | **0** | **0** | **0** | **0** | —— |
| 三腿 | `boot`（活锚基线） | **0** | **0** | **0** | **0** | 0 | 三腿同值 `b21eb530afd3c66c` |
| 三腿 | `k23` | 0 | 0 | 0 | 0 | 0 | 三腿同值 `10d0b9d54e649c10` |

⚠️ **不得把空白读成绿**：`GhostWhite` 是 `Figure`/`Floater` 的 **`Background`**（`DrawBackgroundAndBorder` 所绘），**不是**"内容真绘出"；三内容色**恒 0**。`legC` 的 `GhostWhite=0` 与 `legA`/`legB` 的 `29667`/`29637` 之差＝**附属对象被挪出页**（页盒 `39.81x39.17` DIP ≪ 远锚 666.67 DIP）。

### 2.2 症状门 ＋ 计数（逐腿现取）
| 量 | `legA` | `legB` | `legC` |
|---|---|---|---|
| `alive`／`app_rc`／`failfast`／`unrec`／`magenta`／`ink` | `yes`／`143`／`0`／`0`／`0`／`480000` | 同 | 同 |
| `ns`(k24) | `…FlowDocumentDemo` | 同 | 同 |
| `colors`(k24) | 765 | 724 | 654 |
| `[HC-UNHANDLED]` | **1** | **1** | **1** |
| `entry point named` | **0** | **0** | **0** |
| **`[FSQLL] cLines=1`（内容段）** | **0** | **0** | **0** |
| `[FSQLL]` 总 | 337 | 677 | 345 |
| 内容段 `[FSQTD] cLines=1` | 166 | 336 | 170 |
| `via=viewport`／`via=arrange`／`via=visual` | 83／83／86 | 168／168／171 | 85／85／88 |
| `[FSVIEW]` | 2 | 2 | 2 |
| `app_g1.log` `sha16` | `0e385c0236dc590a` | `74923c2711311694` | `a7c6b5b4d21d9b57` |
| `FRAME k=24 fr_ae_boot` | 220019 | 220546 | 219340 |

⚠️ **计数不可当"稳定量"**：三腿 `via=viewport` ＝ `83／168／85`、`[FSQLL]` 总 ＝ `337／677／345` ⇒ **逐趟时长/点击节拍不同**（本件**不作减法**，也不把次数当"机制"证据）；**唯一稳定读数 ＝ "内容段 `[FSQLL] cLines=1` 恒 0" ∧ "三内容色恒 0"**。

### 2.3 `guard` 判词逐字（现取）＋ 门禁
```
PTS_COLORANCHOR_BASE=frame=boot.png scan=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 min=200 all_zero=yes dead=none
PTS_COLORANCHOR=FAIL k=24 scan=GhostWhite=29667 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 hits=1 expect_min=200 expect_hits=2 baseline=… phase=degraded reason=declared-color-anchor-absent
PTS_COLORANCHOR=NOINFO k=23 reason=no-anchor-registered-for-k23 phase=degraded
PTS_GUARD=FAIL legs=2/2 fails=leg24-placeholder-missing(magenta=0<20000),leg24-named-line(missing-or-err=-),leg23-placeholder-missing(magenta=0<20000),leg23-named-line(missing-or-err=-),leg24-color-anchor-absent(hits=1<2,…),native-ledger-absent(PTS_GAP n=0) direction=in-file phase=degraded
```
（`legA` 逐字如上；`legB` 仅 `29667→29637`；`legC` 为 `scan=GhostWhite=0 … hits=0`。**六项 fails 全部为改前既有状态**，本增量**不新增**任何一项；三腿 `guard rc=1`。）
```
nm -D --defined-only libwpfwin32.so | wc -l  ==  exports.txt 行数  ==  683   （逐名 diff 零差异）
PTSGAP=PASS tool=76 dead=11 artifact=1 ops=64 impl=67 so16=5b7d0ac101673900 exports=683   （rc=0）
DEFREG=PASS declared=225 route_ids=225                                                    （rc=0）
REPORTID=PASS files=322 ids=2233 declared=225                                             （rc=0）
```

---

## §3 验收逐条（对 `T-A42` ③；**逐条带反极性**）

| # | 判据 | 现取 | 判 |
|---|---|---|---|
| **①** | `D0–D3` 逐条现取 ＋ 每条带反极 | 见下 `D0`／`D1`／`D2`／`D3` | **`D0` 证伪前提；`D1` 未达；`D2`／`D3` 成立** |
| **②** | **关键**：`k24` 四具名色各 ≥200px；`[FSQLL]` 对内容段**被调**（0→>0） | 四色 `29667/0/0/0`（`hits=1`）；`[FSQLL] cLines=1` **恒 0（0→0）** | ❌ **未达**（两项都不成立） |
| **③** | 帧面成对（帧 `sha16`／`AE(content)`；不得把空白读成绿） | §2.1／§2.2（三腿 `k24` 帧**两两不同**、`boot` 四色全 0、`k23` 三腿同值；`legC` 背景消失⇒**成对可分**） | ✅（**成对成立**；但"内容像素"未成对变绿 ⇒ 如实记） |
| **④** | `nm==exports`；`PTSGAP=PASS`；`DEFREG`／`REPORTID` rc=0 | §2.3 逐行（`683`／`PASS`／`rc=0`／`rc=0`） | ✅ |
| **⑤** | 症状门（`alive`／`app_rc`／`magenta`／`colors`／`ink`／`ns`）成对 | §2.2（三腿 `alive=yes app_rc=143 failfast=0 unrec=0 magenta=0 ink=480000`、`[HC-UNHANDLED]=1` 未涨） | ✅ |

- **`D0`（分流/诊断）**：判据要求「"视口支有没有跑"可现取」＋「`via=viewport` 与 `[FSQLL] cLines=1` 同量级」。**现取**：`via=viewport = 83／168／85（≠0）` ⇒ **视口支在跑**（承 `T-A41`）；**但内容段 `[FSQLL] cLines=1` 恒 0** ⇒ **真断点在该支之内、且不在门上**（§4）。
  **反极性（必红腿）**：① **假判别器必红** —— `[FSQVP]` 是**具名推断**（行尾 `NOINFO=viewport-branch-callsite`），其反极靠"三标签对账 ＋ 自洽反例 ZERO"承担（承 `T-A41`；本件**未复算**其自洽检查，**不据此下结论**）；② **几何两极（门真↔门假）已真跑** ⇒ 见 §4。
- **`D1`（余 3 具名色各 ≥200px）**：❌ **未达**（`hits=1／1／0`）。**反极性**：**门真态（`legA`／`legB`）与门假态（`legC`）同值（三内容色 `0`）** ⇒ 「几何一动色就齐」**不成立**；且 `PTS_COLORANCHOR=NOINFO k=23 reason=no-anchor-registered-for-k23`（**严禁**把 `k=24` 的锚推广到 `k=23`）。
- **`D2`（baseline 仍全 0／活锚）**：✅ `boot.png` 四色**三腿全 0**（`all_zero=yes dead=none`）。
- **`D3`（帧面成对 ＋ 不得把空白读成绿 ＋ 失败必留痕）**：✅ **成对**：三腿 `k24` 帧**两两不同**（`2d89d393…`／`1487caf7…`／`fa7df922…`），`legB` 与改前**逐字节相同**（强反极）；`k23` 三腿同值、`boot` 三腿同值；`[HC-UNHANDLED]` **恰 1（未涨）**。⚠️ **未成立的部分**：**内容像素在任一门值下都没出现** ⇒ 如实记（**不是**"几何没生效"，而是"门不是断点"）。

---

## §4 反极性（**同一 `.so` ＋ 同一跑器 ＋ 同一装置**，只差**一个 env**：`WPF_PTS_ATT_VSELF`）

| 判据 | `legA` 自洽（门真） | `legB` 原值（门真） | `legC` 远锚（门假） | 改前（`T-A41` 现场） |
|---|---|---|---|---|
| 附属对象 `fsrc.v` | `0` | `20000` | `200000` | `20000` |
| `k24` 帧 | `2d89d393157b0df6` | **`1487caf78fd88886`** | `fa7df9222ebb199f` | **`1487caf78fd88886`**（＝`legB` 逐字节同） |
| `GhostWhite` px | 29667 | 29637 | **0** | 29637 |
| 余 3 具名色 px | `0/0/0` | `0/0/0` | `0/0/0` | `0/0/0` |
| `[FSQLL] cLines=1` | `0` | `0` | `0` | `0` |
| `hits` | `1` | `1` | `0` | `1` |
| 症状门 | 逐格同 | 逐格同 | 逐格同 | 逐格同 |

✅ **本件的反极性是"门真↔门假"那一极（真跑）**：`legC` 把 `ContentRect.v` 抬到 `200000` 文本 ⇒ 由 §1.1 的算式**门必假**，且**旁证成片**（`GhostWhite 29637→0`：附属对象**整块挪出页**）⇒ **门确实是这一门、几何确实到了渲染面**。**而两支的内容像素恒 0** ⇒ **门的取值不改变结果** ⇒ **门不是断点**（`T-A41` 的真断点被证伪）。
✅ **第二条反极性（同一产物撤改动）**：`legB`（`WPF_PTS_ATT_VSELF=0`）的 `k24` 帧与改前**逐字节相同** ⇒ 本改动的"原值态"**逐字可回**（零假值）。

---

## §5 边界 · `NOINFO` · 主动披露

1. **`NOINFO`（逐条给"消掉需要什么"）**：
   - `NOINFO-CONTENT-VIEWPORT-VALUES`（承 `T-A38`/`T-A39`）—— **仍未消**：门的两个操作数（内容段 `_rect.v` 与 `viewportSubpage.v`）**无托管侧直读**；本件只给**算得的**三个取值（`0`／`-20000`／`-200000` 文本）与门值。**消掉需要**：渲染面旁证，或 native 在 `FsQuerySubpageDetails` 打宿主 `viewport` 与子页 `fsrc` 的**成对**值（native **看不到**托管视口 ⇒ 结构性缺信道）。
   - `NOINFO-CONTENT-LINE-BRANCH-UNREACHED`（**本件新读出**）：内容段的**两支造行视觉**（`RenderSimpleLines` 与 `UpdateViewportSimpleLines`）**都没被托管调用**（内容段 `[FSQLL]` 恒 0，而内容段 `[FSQTD] cLines=1` 非零）。**本件的证明射程只到"门值不是成因"**，**不**证"托管侧有缺陷"、**不**证"内容永远画不出"。**消掉需要**：在渲染面定位"内容段的视觉支为什么没被调"（下一增量的靶）。
   - `NOINFO-VIEWPORT-BRANCH-CALLSITE`／`NOINFO-FSQLL-CALLER-DISCRIMINATION`／`NOINFO-SUBPAGE-GEOMETRY-SEMANTICS`／`NOINFO-attached-object-geometry-layout`／`NOINFO-subtrack-para-geometry`：**逐字承** `T-A37`/`A38`/`A39`/`A41`，本件**未消**（其中 `attached-object-geometry-layout` 的 **v 一格**本件已给**可复算的两极**，但 **u／尺寸**仍是本侧自约定）。
2. **本增量的射程（写死，防被读宽）**：本件交付的是 **① 一处可复算的 native 几何改动（`ContentRect.v` 与视口同参照，含同一产物上的门真/门假两极）＋ ② 对 `T-A41` 靶的**证伪** ＋ ③ 一组成对的三腿基线**。它**不是**"排版打通"、**不是**"内容真绘出"、**不是**"色锚转绿"；`[HC-UNHANDLED]=1` 的残留（`FsQueryTrackParaList` 的 `drive-handles-released(page-destroyed)` 诚实拒绝）**未动**。
3. **方案数 ＝ 1 组（三态：自洽／原值／远锚）**（在 `T-A42` ② "最多 3 种方案" 内）。**为何不再堆方案**：由 §1.1 的算式，**任何**只动 `ContentRect.v` 的取值都**不可能**让门从"假"变"真"（改前门**本来就真**）；三态已把**门真（×2）↔ 门假（×1）** 覆盖 ⇒ 按 ② 的"**失败即如实报停止（允许判合法终点）**"收口：**判据 ② 未达**，且 **`T-A41` 指认的靶被证伪** ⇒ 本件的合法产出是**具名的下一靶**（§0.7／§5-1）＋**可复算的三腿成对基线**。
4. **未做的（防被读宽）**：未跑整趟 `verify-all`；未跑 `static-jaws-check.sh`；未判相位；**未**新增任何 `D-G<digits>` 登记编号；未跑 `--all-arms`；未改 `upstream/**`；**未**改托管件／生成器。
5. **复述位（`docs/ROUTES.md`／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/HANDOFF-NEXT.md`／`src/WpfGfx.Linux.Native/src/win32_classification.c`）**：本趟**移动的字段只有 `so16`**（`tool/dead/artifact/ops/impl/exports` **逐格未动**）⇒ **理由有机器证**：`pts-gap-count-check.sh` 现取**无 `SITE-DRIFT`**，只印 `SITE-HISTORICAL-ONLY samples/WpfFeatureProbe/KNOWN-DEFECTS.md tool hist=5`／`ops hist=2`／`impl hist=2`（**自引旧代工件的历史行**，**不参与现值判定**）；`win32_classification.c` 不含 `so16`（`grep -c` ＝ 0）且其「可操作 64／实现口径 67」与现取 `ops=64 impl=67` **逐数相符**（改它还会改 `.so` ⇒ **不必**）。⇒ 这几件的"复述位现值位"结论 ＝ `NOINFO(reason=no-current-value-cell-relevantly-moved)`，**不是"漏改"**。**唯一随动**是 `HANDOFF-NEXT.md`（`§3` 追加 `T-A42` dated 行；**只增不改**）。
6. **跨代／跨装置不可比（纪律 31/32）**："改前"列取自 `T-A36`/`T-A37`/`T-A39`/`T-A41` 的**在册**证据（**同 `.so` 代** `dd9865c38e18ed81`）⇒ 只报**结果**（`legB` 帧同值等），**不做减法**承重；三腿**同一装置**（`:231`）＋**同一产物**（`5b7d0ac101673900`）＋**同批工具**（§2 三个 `sha16`）。
7. **侧效（如实披露，未进仓）**：`~/tA42-work/`（`bak/` 改前件 ＋ `run3.sh` 三腿脚本 ＋ `legA.log`／`legB.log`／`run3.log`）；仓内应用安装由 `sync-applocal.sh` 刷 `.so` **一件**（`drift=1 → 0`；三腿逐腿 `POSTSHIM … == authority`）。

---

## §6 落盘后复跑（现取；`④` 的成对读数）
- `bash build/MilBridge/tools/defect-registry-check.sh` ⇒ **`DEFREG=PASS declared=225 route_ids=225`**（rc=0）＋ `DEFREG_DECLDRIFT=0 keys=-`（⚠️ 本趟**未改** `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 的现值位行 ⇒ 与 `T-A41` 不同，**不需**主控重发 `declared.tsv`；若后续有人动 route 件，仍按纪律 15 由主控同趟重发）。
- `bash build/MilBridge/tools/report-id-domain-check.sh` ⇒ **`REPORTID=PASS files=322 ids=2233 declared=225`**（rc=0；落盘前 **`files=321`** ⇒ 本载体 ＋1 件。⚠️ **`ids` 不写死**：它是"报告件集合上的派生量"、而**本载体自己就在该集合里** ⇒ 任何一次改字都会动它）。
- `bash build/MilBridge/tools/pts-gap-count-check.sh` ⇒ **`PTSGAP=PASS tool=76 dead=11 artifact=1 ops=64 impl=67 so16=5b7d0ac101673900 exports=683`**（rc=0）。
- `nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so | wc -l` ＝ **683** ＝ `wc -l bin/exports.txt` ＝ **683**（逐名 `diff` **零差异**）。

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-vgeom-impl-report.md | sha256sum | cut -c1-16`）= da4e7caf72f72499

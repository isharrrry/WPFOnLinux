# `P1-tail2` · `T-A39` · native 子页视口几何自洽（`NATIVE-PTS-SUBPAGE-VIEWPORT-GEOMETRY`）—— 实现报告（**判决：证伪**）

- **读时**：`2026-09-30T18:1x+0800`（本席现取，各条另注）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，`HEAD=140265d48f7c6e993e25ce370f9d35147339138d`（现取，**未换代**）。
- **改前件备份（仓外 `~/tA39-work/bak/`，`cp -p` 取在**任何写之前**）**：`win32_pts.c.bak`（**`1d8e3cac55cc473e`**）／`libwpfwin32.so.606dad49.bak`（**`606dad49ae7b34a1`**）／`exports.txt.bak`（`860a3abe4a64f1c5`，683 行）／`pts-gap-decl.txt.bak`（`9e11af5fc8901ca3`）。
- **本增量对产品的改动 = `0` 字节**（仪器在**两趟仪器构建**里用，**回滚后重编逐字节回原代**：见 §0.3）。⇒ **未改** `docs/**`／`README.md`／`HANDOFF-NEXT.md`／`KNOWN-DEFECTS.md`／`win32_classification.c`／`tools/pts-gap-decl.txt`／`bin/exports.txt`／`build/*.Linux/**`（生成件）／`build/shims/**`／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`（**只读跑**判据件）。
- **新建（仓内）**：证据目录 `build/MilBridge/tests/PtsPagesProbe/evidence-tail2g/`（4 腿：`sample1/`／`sample2/`＋仪器腿 `instr-anchor-sweep/`／`instr-gate-probe/`）／本载体。
- **重活**：**3 趟构建 ＋ 4 趟腿**（＝4 次跑器调用 ⇒ 8 条腿样本）全走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- <cmd>`（`HEAVYSLOT=ACQUIRED`／`RELEASED` 逐趟可见；**现取到的持有**：`3s`（仪器 A 构建）／`3s`（仪器 A＋B 构建）／`36s`（锚扫描腿）；另两趟的 `RELEASED` 行被本席的 `grep` 过滤掉、**未现取 ⇒ 不写**）；进程只按 PID；禁 `sleep` 轮询；写前 `cp -p` 备份；模式守恒。
- **行号纪律**：本件行号**仅本次有效**；引件一律给**内容锚**。
- **口径**：一切读数**本席现取**（`sha256sum`／`nm`／`grep -c`／只读 `python3`＋`PIL` 解 PNG／`bash build/MilBridge/tools/pts-pages-guard.sh --legs …`／`pts-gap-count-check.sh`／`defect-registry-check.sh`／`report-id-domain-check.sh`）；`P1-tail2-viewport-recon.md`（`T-A38`）／`P1-tail2-attachcontent-impl-report.md`（`T-A37`）**只作对照**，其读数**一条未抄**。

---

## §0 结论速览（自包含）

1. 🔴 **判决：`NATIVE-PTS-SUBPAGE-VIEWPORT-GEOMETRY` 判负（前提被证伪）**。`T-A38 §4.3` 的断点归属（"`:3371` 的视口相交门对内容段恒走不相交"）**不成立**：本席造了一件**必然让该门为真**的仪器 —— 把内容段的 `_rect` 撑成 `[−2^30, +2^31−1)`（**覆盖任何有限视口**的带）—— 而 **`[FSQLL] cLines=1` 仍恒 0**（`instr-gate-probe`，整趟）。⇒ 该门对内容段**从未被执行**（不是"执行了但判假"）。
2. **第二件独立仪器（锚扫描）同向**：把附属对象的**页矩形锚**按"每轮推进一格"扫描 `{0,2000,4000,8000,16000,32000,64000,128000}`（每值 **≥42** 轮，现取逐值覆盖数），**八个取值下 `[FSQLL] cLines=1` 全为 0**、余 3 具名色仍全 0。**射程（写死，不要读宽）**：门的通过集（把右操作数写成 `Δ` ＝ 附属对象页 `v`、左操作数写成 `Vp`）＝ `[Vp.v − h, Vp.v + Vp.dv]`（`h` ＝ 内容段 `_rect.dv`）；本扫描只能**把 `Δ` 这条变量排除**（`0…128000` 全不通过 ⇒ `Δ` 不可能是"补上就绿"的那一格），**单独**不能排除"通过集很窄、被 2 倍步长跨过" ⇒ **主证据取仪器 B**（§0.1：门被置**必真**）。扫描的**另一重作用**是**成对证明仪器真进了渲染面**（`k24` 帧 `1487caf78fd88886→f0c4c11d64666f63`、`GhostWhite` `29637→25371` px，而 `k23` 帧不变）⇒ 读数**不是空转**。
3. ✅ **产品面零改动（回滚可复算）**：`win32_pts.c` 回到 **`1d8e3cac55cc473e`**（与备份逐字节相同）、重编 `.so` 逐字节回到 **`606dad49ae7b34a1`**（＝改前代）、`bin/exports.txt` 逐字节不变（`cmp` 零差异）⇒ **没有把任何未验证的几何改动落进树**（硬边界"永不假成功／零假值"）。
4. 🔴 **前沿（具名下一增量）**：**内容段的"造行视觉"两支都从未被托管调用**。现取（四腿**逐腿同形**）：内容段每轮恰 **1 次** `[FSQTD]`（`cLines=1`：sample1 `810`＝轮数 `817`／sample2 `160`＝`167`／仪器腿 `166`＝`173`、`152`＝`159`），而 `[FSQLL]` 对内容段**恒 0**；`[FSPARALIST-FILL-SP]`＝内容段 `[FSQTD]`＝`FsQuerySubpageDetails`（非 `nil`）**三数同值**。⇒ 到达内容段的只有**查询支**（`FsQueryTextDetails` 的单点调用），**两支造行视觉都没到**：
   - `ValidateVisual`→`RenderSimpleLines`（`:3218`）若到过 ⇒ 必打 `[FSQLL]`（现取 0）；
   - `UpdateViewport`→`UpdateViewportSimpleLines`（`:3389`）若到过 ⇒ 门已被仪器置**必真** ⇒ 也必打 `[FSQLL]`（现取 0）。
   ⇒ 下一增量的**唯一可做项**＝**在渲染面定位"内容段的视觉支为什么没被调"**（本件已给出两件**可复算**仪器与四腿成对基线，见 §1／§2）。
5. ✅ **症状门 ＋ 帧面成对**：四腿 `alive=yes`／`app_rc=143`／`failfast=0`／`magenta=0`／`ink=480000`／`ns=…FlowDocumentDemo` **逐格相同**；`[HC-UNHANDLED]` **四腿各恰 1**（**未涨**）；`k23` 帧四腿**同值** `10d0b9d54e649c10`；`boot` 帧四腿同值 `b21eb530afd3c66c`。**产品两独立样本**的 `k24` 帧与改前（`T-A36`／`T-A37` 在册 `1487caf78fd88886`）**逐字节相同**。
6. ✅ **仪器非空转（成对证据）**：两条仪器腿的 `k24` 帧**确实变**（`f0c4c11d64666f63`／`8afb16620d62c7de`），`GhostWhite` `29637→25371／25155` px，而 `k23` 帧**不变** ⇒ 几何确实进了渲染面、只是**换不来内容像素**。
7. ✅ **门禁（④）**：`nm -D --defined-only` ＝ `exports.txt` ＝ **683**（逐名 `diff` 零差异）；`PTSGAP=PASS tool=76 dead=11 artifact=1 ops=64 impl=67 so16=606dad49ae7b34a1 exports=683`（rc=0，**在本件落盘后重跑现取**）；`DEFREG=PASS declared=225 route_ids=225`（rc=0）；`REPORTID=PASS files=320 ids=2230 declared=225`（rc=0；**本件落盘后**现取 ⇒ `ids` 与落盘前**同为 2230** ⇒ 本件未引入任何新编号）。因**代际未变**，**复述位现值位无需随动**（机读证据即 `PTSGAP=PASS` 的 `so16`／`exports` 两格）。

---

## §1 仪器（**只在仪器腿用；产品面 0 字节**，逐处原文）

### 1.1 仪器 A：附属对象**页矩形锚**扫描（`WPF_PTS_ATT_SWEEP`）
```c
/* ── ⏪ `T-A39` 仪器：附属对象页矩形锚扫描 —— 把"本侧唯一可动的那个操作数"做成扫描量 ── */
static int g_pts_att_sweep_idx = 0;                 /* 轮号（每页查询 `New` 推进一格） */
static const int wpf_pts_att_sweep_list[] = { 0, 2000, 4000, 8000, 16000, 32000, 64000, 128000 };
#define WPF_PTS_ATT_BAND_U 0
#define WPF_PTS_ATT_BAND_V 0
static int wpf_pts_att_anchor_v(void)
{
    const char *s = getenv("WPF_PTS_ATT_SWEEP");
    if (s && *s) { int n = (int)(sizeof(wpf_pts_att_sweep_list)/sizeof(wpf_pts_att_sweep_list[0]));
                   return wpf_pts_att_sweep_list[(g_pts_att_sweep_idx % n + n) % n]; }
    const char *f = getenv("WPF_PTS_ATT_ANCHOR_V");
    if (f && *f) { int v = atoi(f); if (v >= 0) return v; }
    return WPF_PTS_ATT_BAND_V;
}
static void wpf_pts_att_geometry(int idx, int is_figure, wpf_pts_fsrect *out)
{   /* 原实现：out->u = 30000 + (idx%4)*30000; out->v = 20000 + (idx/4)*40000; */
    out->du = is_figure ? WPF_PTS_ATT_FIG_DU : WPF_PTS_ATT_FLO_DU;
    out->dv = is_figure ? WPF_PTS_ATT_FIG_DV : WPF_PTS_ATT_FLO_DV;
    out->u  = WPF_PTS_ATT_BAND_U;          /* ← 仪器：页带原点（原值 30000+…） */
    out->v  = wpf_pts_att_anchor_v();      /* ← 仪器：扫描值（原值 20000+…） */
    fprintf(stderr, "[ATT-GEOM] idx=%d is_figure=%d sweep_idx=%d anchor_v=%d u=%d du=%d dv=%d "
                    "src=page-band-origin(FsQueryPageDetails.trackdescr.fsrc) "
                    "v=ANCHOR-FROM-DECLARED-PAGE-BAND\n", idx, is_figure, g_pts_att_sweep_idx,
            out->v, out->u, out->du, out->dv);
}
```
推进点（`FsQueryPageDetails` 的成功路径，与 `[VIS]` 判别器同源）：
```c
g_pts_qpd_prev_page = (const void *)pPage;
if (fskupd == WPF_PTS_FSKUPD_NEW) g_pts_att_sweep_idx++;   /* 仪器：每轮推进一格 */
```
**为什么这是"读数"而不是"调参"**：托管视口（`:3371` 门的**左操作数**）本侧无源、不可读（承 `T-A38 §5` 的 `NOINFO-CONTENT-VIEWPORT-VALUES`）；本席把**右操作数**（本侧声明的附属对象页矩形 ⇒ `ContentRect`）做成自变量，用"同轮内是否出现 `[FSQLL] cLines=1`"**反演**门的通过集。**`du/dv` 一字未动**（仍取 `FSCBK` 回调给出的对象尺寸）。

### 1.2 仪器 B：**门必真探针**（`WPF_PTS_GATE_PROBE`）
```c
/* FsQuerySubtrackDetails（内容树支） */
o->u  = 0; o->v = 0;
if (obj->in_subpage && getenv("WPF_PTS_GATE_PROBE") && getenv("WPF_PTS_GATE_PROBE")[0] == '1')
    o->v = -0x40000000;                    /* ← 内容段 `_rect.v` 抬到 −2^30 */
/* FsQuerySubtrackParaList（内容树支） */
if (obj->in_subpage && obj->child_objs[i] && obj->child_objs[i]->fl_ok) {
    int hh = 0; for (int k = 0; k < ...->fl_nlines; k++) hh += ascent + descent;
    rg[i].dvr_used = hh;
}
if (obj->in_subpage && getenv("WPF_PTS_GATE_PROBE") && getenv("WPF_PTS_GATE_PROBE")[0] == '1')
    rg[i].dvr_used = 0x7FFFFFFF;           /* ← `_rect.dv` 撑到 2^31−1 */
```
⇒ 内容段 `_rect` ＝ `[−2^30, −2^30 + (2^31−1)]` ＝ **覆盖任何有限视口**的带 ⇒ `IntersectsWithRectOnV` **必真**（除 `Vp.dv` 为负或 `Vp.v` 超出该带的病态情形）。**用途唯一**：判定门**有没有被走到**。⚠️ 这是**伪造几何**（`P1-tail2-viewport-recon.md` 明禁）⇒ **只作仪器、绝不过夜**（§0.3 已回滚）。

### 1.3 三趟构建与回滚（现取）
| 趟 | 源 sha16 | 产物 sha16 | 用途 |
|---|---|---|---|
| 仪器 A | —— | `426e79a1b0ab8e4c` | `instr-anchor-sweep` |
| 仪器 A＋B | —— | `6b6fbacc84916be5` | `instr-gate-probe` |
| **回滚重编** | **`1d8e3cac55cc473e`**（＝备份逐字节同） | **`606dad49ae7b34a1`**（＝改前代逐字节同） | `sample1`／`sample2` |

---

## §2 四腿成对读数（**同一装置 `:231`／同批工具**：`runner_sha16=330a90f1f0ac28e4`／`session_sha16=f1a582d9ea9788c9`／`guard_sha16=962fec114b2d0692`；A 臂，clicks `[24,23]`）

### 2.1 症状门 ＋ 帧面（逐腿现取）
| 腿 | `.so` | `alive` | `app_rc` | `failfast` | `magenta` | `colors`(k24) | `ink` | `ns`(k24) | `k24` `fr_sha` | `k23` `fr_sha` |
|---|---|---|---|---|---|---|---|---|---|---|
| `sample1`（产品·样本 1） | `606dad49ae7b34a1` | yes | 143 | 0 | 0 | 724 | 480000 | `…FlowDocumentDemo` | **`1487caf78fd88886`** | `10d0b9d54e649c10` |
| `sample2`（产品·样本 2） | `606dad49ae7b34a1` | yes | 143 | 0 | 0 | 724 | 480000 | 同 | **`1487caf78fd88886`** | `10d0b9d54e649c10` |
| `instr-anchor-sweep`（仪器 A） | `426e79a1b0ab8e4c` | yes | 143 | 0 | 0 | 693 | 480000 | 同 | `f0c4c11d64666f63` | `10d0b9d54e649c10` |
| `instr-gate-probe`（仪器 A＋B） | `6b6fbacc84916be5` | yes | 143 | 0 | 0 | 706 | 480000 | 同 | `8afb16620d62c7de` | `10d0b9d54e649c10` |

`boot.png` 四腿**同值** `b21eb530afd3c66c`；`[HC-UNHANDLED]` **四腿各恰 1**；`device.txt` 四腿 `X_UP=yes display=:231`；`five_stable=yes`。

### 2.2 计数成对（`grep`／正则现取；`app_g1.log` 指纹逐腿给出）
| 量 | `sample1` | `sample2` | `instr-anchor-sweep` | `instr-gate-probe` |
|---|---|---|---|---|
| `app_g1.log` `sha16`／字节 | `92664a9ced9c10ba`／10132736 | `2ff03b8b71b8ac74`／2152173 | `ec1ee6bb891365fd`／2322776 | `4fdfdd3a45134e91`／2129578 |
| 轮数（`[QPD] fskupd=2`） | 817 | 167 | 173 | 159 |
| `[FSQLL]` 总／`cLines` 直方图 | 1625｜`8×812,6×812,2×1` | 325｜`8×162,6×162,2×1` | 337｜`8×168,6×168,2×1` | 309｜`8×154,6×154,2×1` |
| **`[FSQLL] cLines=1`（＝内容段）** | **0** | **0** | **0** | **0** |
| 内容段 `[FSQTD] cLines=1` | 810 | 160 | 166 | 152 |
| `[FSPARALIST-FILL-SP]` | 810 | 160 | 166 | 152 |
| `FsQuerySubpageDetails subpage=0x…`（非 `nil`） | 810 | 160 | 166 | 152 |
| `FsQuerySubpageDetails subpage=(nil)` | 816 | 166 | 172 | 158 |
| 色锚 `hits`（`k24`，`expect>=200px&hits>=2`） | **1** | **1** | **1** | **1** |

**逐字样本（`sample1`／`instr-anchor-sweep`）**：
```
[FSQLL] rc=0 reason=ok entry=FsQueryLineListSingle … cLines=8 …     ← 页面级段（宿主）
[FSQLL] rc=0 reason=ok entry=FsQueryLineListSingle … cLines=6 …     ← 页面级段（两枚 6 行）
[FSQTD] rc=0 reason=ok entry=FsQueryTextDetails … parah=0x…3c034 fsktd=1 cLines=1 dcpFirst=0 dcpLim=41
        out=WRITTEN bytes=112 src=ledger:fl_line[](pfnFormatLine+fsflres-end)     ← **内容段有 FSQTD**
[FSQLL] ……                                                          ← **内容段的 `[FSQLL]` 恒缺席**
[ATT-GEOM] idx=0 is_figure=0 sweep_idx=1 anchor_v=2000 u=0 du=85500 dv=30000
           src=page-band-origin(FsQueryPageDetails.trackdescr.fsrc) v=ANCHOR-FROM-DECLARED-PAGE-BAND
```
**锚扫描的逐值覆盖（现取，`anchor_v` 计数）**：`0→84`｜`2000→46`｜`4000→82`｜`8000→42`｜`16000→84`｜`32000→42`｜`64000→84`｜`128000→42`（**八值全部被覆盖 ≥42 轮**，且八值下 `[FSQLL] cLines=1` **全 0**）。

---

## §3 验收逐条（对 `T-A39` ③；**逐条带反极性**）

| # | 判据 | 现取 | 判 |
|---|---|---|---|
| **①** | `A38 ③` 的 `D0–D4` 逐条 ＋ 反极性 | 见下 | **部分不成立（如实）** |
| **②** | `k24` 四具名色各 `≥200px`；`[FSQLL]` 对内容段**被调** | 四色 `GhostWhite=29637,Beige=0,DarkGreen=0,LightGoldenrodYellow=0`（`hits=1`）；`[FSQLL] cLines=1` **0** | ❌ **未达** |
| **③** | 帧面成对（`sha16`／`AE`；**不把空白读成绿**） | §2.1（产品两样本同值＝改前值；仪器两腿 `k24` 真变、`k23` 不变） | ✅ |
| **④** | `nm==exports`；`PTSGAP=PASS`；`DEFREG`／`REPORTID` rc=0 | §0.7 | ✅ |
| **⑤** | 症状门（`alive`／`app_rc`／`magenta`／`colors`／`ink`／`ns`）成对 | §2.1（四腿逐格同） | ✅ |

- **`D0`（分流/诊断）**：判据要求"`[FSQLL] cLines=1` 首次出现 ⇒ 断点属 `:3371` 门"。**现取：恒 0**；且**仪器 B**把门**置必真**后**仍 0** ⇒ 判据里"若仍为 0 ⇒ 断点改判"的那一支**成立**，本件据此**判 `(丙)` 负**。**反极性（必红腿）**：仪器 A 换"假几何"（页带原点 ＋ 八值扫描）**换不来** `cLines=1`、也换不来任何新色 ⇒ **没有**"用假几何换绿"的通道被打开（`P8`）；同时仪器 A 的 `k24` 帧**确实变** ⇒ 该反极性腿**不是**"没插上电"的空转。
- **`D1`（余 3 色）**：❌ 未达；**反极性**：仪器两腿仍 `hits=1`（`Beige`／`DarkGreen`／`LightGoldenrodYellow` 全 0）⇒ **成对**（"几何一动色就齐"是假的）。
- **`D2`（baseline 仍全 0）**：✅ `boot.png` 四色全 0、`LightGray=44`（**未入集**），四腿同。
- **`D3`（帧面成对）**：✅ `k24`：产品两样本 `1487caf78fd88886`（＝改前）；仪器 A `f0c4c11d64666f63`；仪器 B `8afb16620d62c7de`。差异分量落在**内容区**（`GhostWhite` 块位移＋`colors` 724→693/706），**不是**仅蓝块/页签位移（`k23` 帧四腿同值）。**两独立样本**（`sample1`／`sample2`）`k24` **同值**（而计数不同：`1625` vs `325` ⇒ 与仓内既有结论一致：只有帧可复现）。
- **`D4`（症状门无回归＋失败必留痕）**：✅ 四腿六项逐格同、`[HC-UNHANDLED]=1` 未涨；**几何不成立时必留痕**：`[ATT-GEOM]`（仪器的每次取几何都留痕，含 `sweep_idx`／`anchor_v`／`src=`）＋各入口既有 `[FS_PAGE_GAP]`／`reason=` 面；仪器与环境（探头）**逐条可辨**，不与"真 0 次"混同。

---

## §4 边界 · `NOINFO` · 主动披露

1. **方案数 ＝ 2**（仪器 A 锚扫描；仪器 B 门必真探针）＋1 趟回滚复算 ⇒ 在 `T-A39` ② "最多 3 种方案" 内；按 ② 的"**失败即如实报停止（允许判合法终点）**"收口：本增量**不是一个可做项**（其前提已证伪），故本席**不落**任何产品改动。
2. **未做的（防被读宽）**：未跑整趟 `verify-all`；未跑 `static-jaws-check.sh`；未判相位；未动任何牙本体；未新增 `D-G<digits>` 编号；未 `git add/commit/push`；未改任何生成件。
3. **`NOINFO`（逐条给"消掉需要什么"）**：
   - `NOINFO-CONTENT-VIEWPORT-VALUES`（承 `T-A38`）——**状态更新**：本件用**门必真探针**把"门被走到 ∧ 判假"这一支**排掉** ⇒ 该 `NOINFO` **不再是**本断点的成因；**仍未消**的部分＝"内容段 `UpdateViewport`／`ValidateVisual` 到底由谁（不）调用"（托管面读数）。**消掉需要**：渲染面旁证（或 `Invariant.Assert` 类**响亮**位点触发）。
   - `NOINFO-SUBPAGE-GEOMETRY-SEMANTICS`／`NOINFO-FSQLL-CALLER-DISCRIMINATION`／`NOINFO-FIGURE-ONARRANGE-HANDLE`：**逐字承** `T-A38`，本件**未消**。
   - **新读出**：`NOINFO-CONTENT-VISUAL-ENTRYPOINT`（**本件核心边界**）——"内容段每轮恰 1 次 `[FSQTD]` 而 `[FSQLL]` 恒 0"只证明**两支造行视觉都没到**，**不能**分辨**哪一支**（`ValidateVisual`／`UpdateViewport`）与该次 `FSQTD` 有关（本侧只见查询面）。**消掉需要**：渲染面旁证，或本侧把**每次** `FsQueryTextDetails` 的**调用者身份**做成可判（例如按"同轮内第几次 + 紧邻事件"作判别器）。
4. **射程（写死）**：本件**只**证"（i）几何锚不是自变量（八值扫描）；（ii）`:3371` 门对内容段从未被走到（门必真探针）；（iii）产品面零改动"。**不**证"内容段永远画不出"，**不**证"托管侧有缺陷"（本侧无该面读数）；**不**把"帧面变了"读成"内容画出来了"（仪器两腿 `colors` 反降：724→693/706，色锚 `hits` 仍 1）。
5. **反极性（本件自己的两极化）**：**正极**＝产品两样本（`606dad49…`）⇒ 帧/症状/计数与改前逐格同；**反极**＝仪器两腿（几何改）⇒ `k24` 帧**必变**、`k23` 帧**不变**、`[FSQLL] cLines=1` 与色锚**不变**。⇒ "几何确实进了渲染面"与"几何换不来内容"**成对**，两端都不是空转。
6. **跨代／跨装置不可比（纪律 31/32）**：本件"改前"列取自 `evidence-tail2f/sample3`（**同一 `.so` 代** `606dad49ae7b34a1`）⇒ 只报**结果**（帧同值等），**不做减法**承重；四腿**同一趟装置**（`:231`）＋**同批工具**（§2 三个 `sha16`）。
7. **侧效（如实披露）**：`~/tA39-work/`（`bak/` 改前件 ＋ `legs/` 两趟仪器腿 ＋ 三件跑腿脚本 `build1.sh`／`build2.sh`／`build-revert.sh`／`legs-sweep.sh`／`legs-gateprobe.sh`／`legs-product.sh`）；仓内应用安装**一字未动**（`sync-applocal.sh --check … drift=0` 逐腿现取；`POSTSHIM: shim=606dad49ae7b34a1 == authority`）。
8. **相位与终局判读（如实）**：相位未翻转（判据件 `pts-pages-guard.sh` 的 `PTS-DIRECTION … phase=degraded` 未动）；本增量**不是**"能力前进"（产品面 0 字节、帧面 0 像素），而是**把前沿判据本身证伪**并**消掉一条错误的靶**——按本仓"前沿＝具名增量"的口径，本件的合法产出是**具名的下一增量**（§0.4）＋**两件可复算仪器**＋**四腿成对基线**。

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-subgeom-impl-report.md | sha256sum | cut -c1-16`）= 575784fab1dc53d6

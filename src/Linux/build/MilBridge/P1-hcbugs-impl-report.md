# `P1` hc demo 两缺陷修（真 `v` 几何 ＋ 跨窗句柄拒发）—— 实现报告（`T-B3`）

- **读时**：`2026-10-02T10:20+0800 … 10:45+0800`（本席现取，各条另注）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=faf0c7314a3bbfdb4b0c403fb8c742a16b5ace40`（现取）。
- **选靶**：照 `build/MilBridge/P1-hcbugs-recon.md`（`T-B1`）的**唯一选靶（甲·native）** —— 一处两改，全落在 `src/WpfGfx.Linux.Native/src/win32_pts.c`。
- **件指纹（现取，`sha256` 前 16 位）**：`src/win32_pts.c eb0fcd59f21fd746`｜`bin/libwpfwin32.so **22e147d144b901c0**`（`554152 B`、`846` 导出，与 `bin/exports.txt` 逐名相等）｜`tools/pts-gap-decl.txt`（`PTSGAP-DECL` 行 `so16` 重锚）。
- **行号纪律**：下文 `win32_pts.c:` 行号**仅本次有效**，一律附**内容锚原文**（改动前位形按 recon／改后位形本席现取）。
- **副本先行**：写前 `cp -p` 四件到 `~/tb3-work/`（`win32_pts.c.orig`／`exports.txt.orig`／`libwpfwin32.so.orig`／`pts-gap-decl.txt.orig`）。**旧 `.so` ＝ `df27801beb222f05`**，本报告的「改前」帧/读数即由它现取（同装置同流程）。
- **装置**：`Xvfb :233 -screen 0 1280x1024x24` ＋ `xfwm4 --compositor=off`；demo ＝ `bash ~/run-hc.sh`（缺省档、窗口 `800x600@(0,0)`）；点击坐标取 recon §1.2；重活走 `~/heavy-slot.sh`；进程只按 PID。

---

## §1 两处改动（逐处：件:行 ＋ 原文 ＋ 作者性）

### 1.1 缺陷①「同 track 各段共 `v`」——**真 `v` 几何**

**第一处断点（现取）**：`win32_pts.c` 的 `FsQuerySubtrackParaList` 填充支，原**只**给**内容子页树**填段高：

```c
            /* ⏪ `T-A37`：**内容子页树**里，段高取该段**真行台账**的 `Σ(ascent+descent)`（否则为 0 ⇒
               零高矩形 ⇒ 内容不可见）；非内容树逐字保持 `0` ＋ 既有 `NOINFO`。 */
            if (obj->in_subpage && obj->child_objs[i] && obj->child_objs[i]->fl_ok) { ... rg[i].dvr_used = hh; }
```

⇒ **主文本段（`in_subpage==0`）`dvr_used` 恒 0** ⇒ 宿主 `PtsHelper.cs:177-180`（生成件对位
`PtsHelper.Linux.cs:202-208`）的 `rcPara.v = rcTrackContent.v + dvrPara + dvrTopSpace`／
`dvrPara += dvrUsed` ⇒ 同 track **逐段 `v` 全等于首段 `v`**（`[TPCL] … rectV=0` 逐段全 0，见 §2.2-①）。

**改法（外科手术式）**：新增**真几何**辅助 `wpf_pts_sub_v_extent(const wpf_pts_subtrack *)`
（`win32_pts.c:7715` 起，内容锚 `static int wpf_pts_sub_v_extent(const wpf_pts_subtrack *root)`）
——**段高 ＝ 该子树逐叶段 Σ 行(`dvrAscent`+`dvrDescent`)**，几何源＝
`pfnFormatLine` 的**真返回值**行台账（与 `[FSTEXTDETAILS].c_lines`／`ur_start` **同源同操作数**；
复用既有唯一可用性判据 `wpf_pts_fl_usable`）。**取不到返 `-1` ⇒ 保持 0 ＋ 具名**
（`g_pts_vgeo_short`／`[FSQSPL]` 行的 `NOINFO`），**绝不**用 0 或常数冒充；`dvrTopSpace` 本侧
**无几何源** ⇒ 恒 0 ＋ 具名 `NOINFO=no-top-space-source`。

- **射程**：两处填充支各一次调用 ——
  · `FsQuerySubtrackParaList`（`win32_pts.c:9706`，内容锚 `int hv = wpf_pts_sub_v_extent(obj->child_objs[i]);`）——原 `if (obj->in_subpage && obj->child_objs[i] && obj->child_objs[i]->fl_ok)` 换成**无条件**（凡有可用行台账者一律填）；
  · `FsQueryTrackParaList`（**页轨顶层容器段**，`win32_pts.c:9243`，内容锚 `int hv = wpf_pts_sub_v_extent(para_obj);`）——原来此字段缺省不填（`WPF_PTS_FSP_PL_DVR` 缺省 0 把整块编掉），现按同一函数填真值。
- **不改**：`WPF_PTS_FSP_PL_DVR` 那一族副本旋钮**一个字节不动**（它们取 `g_pts_lm1_led[]` 的
  `seg_h=16` 常数，**不是**真几何；本增量走的是**新的真几何源**，不冒充、不复用常数）。

### 1.2 缺陷②「跨窗陈旧句柄 ⇒ 第三 tab `FailFast`」——**句柄发放收严**

**第一处断点（现取）**：`win32_pts.c` 交句柄处 —— `FsQueryTrackParaList` 的
`rg[i].pfsparaclient = (void *)dp->fsp_pl_cur;` 与 `FsQuerySubtrackParaList` 的
`rg[i].pfsparaclient = (void *)obj->child_clients[i];`。

**根因（现取，改前现场原文逐字）**：`hc-run-092614.log` 末三行 ——

```
[WINDOW-SPLIT] where=FsQueryTrackParaList window=out action=summarize-only … handles_live=0 calls136=0 in_enum=3 out_sum=156 out_refused=14246 refused=14246 calls=14402 v=OUT-WINDOW-REFUSED(handles-released/page-destroyed)
[FSPARALIST-FILL] rc=0 … cParas=1 h0=0x5 src=managed-176 run=site=probe-in win=in gen=1 quad=4 hold=0 … ok=1645 gap=0 …
Unrecoverable system error.: Handle has been already released.
```

⇒ `FsDestroyPage` **之后**（`handles_live=0`）仍把**页销毁前造的** `fsp_pl_cur`（`h0=0x5`）当
`pfsparaclient` 交出去 ⇒ 托管 `PtsContext.HandleToObject` 撞
`PtsContext.cs:248 Invariant.Assert("Handle has been already released.")` ⇒ `Environment.FailFast`
（**不可捕获**）⇒ `rc=134`。`T-A47` 的收窄（`QTP-LIVE-NARROW`）以「`fsp_pl_cur` 是本侧自持」
为由放行，**该前提被现场推翻**（槽确已被回收）。

**改法**：「**本窗新造 ∧ 在册 live**」的**可判**形式 ＝ **句柄的造出代 ＝ 当前页销毁代**：

- `wpf_pts_doc` 新增两字段（`win32_pts.c:271-272`，内容锚 `int fsp_pl_epoch;`／`int page_destroy_n;`）：
  `page_destroy_n`（`FsDestroyPage` **只增**，`win32_pts.c:7307`，内容锚 `ddp->page_destroy_n++;`）
  与 `fsp_pl_epoch`（**每一次** `+176 CreateParaclient` 真返回时写当时的 `page_destroy_n`：
  探针窗内 `src_in`／窗外 `src_out`／查询期 `query-frame` 四处）；
- `wpf_pts_subtrack` 新增 `int child_clients_epoch`（同源，`win32_pts.c:9657`，内容锚
  `obj->child_clients_epoch = dp->page_destroy_n;`）；
- 判据 `wpf_pts_handle_epoch_stale()`（`win32_pts.c:2940`，内容锚
  `return (d && d->fsp_pl_epoch != d->page_destroy_n) ? 1 : 0;`）＝ `fsp_pl_epoch != page_destroy_n`
  ⇒ 交出去必撞 `FailFast`；
- **两处填充支**各加一条 `else if`（照本件既有的 `no-legal-pfspara-in-this-run` 体例 —— recon 现取位
  `win32_pts.c:9122`）：`win32_pts.c:9165`（`FsQueryTrackParaList`）／`:9638`
  （`FsQuerySubtrackParaList`），`reason = "stale-paraclient-across-page-destroy(…)";`
  ＋ `g_pts_handle_stale_refused++`，**出参一字不写**。
  `FsQuerySubtrackParaList` 的 `drive-handles-released` 那条**原样保留**（它与本条是两回事）。
- **反极性闸**：`WPF_PTS_HANDLE_STRICT`（缺省 `1`＝收严生效；显式 `0` ⇒ 逐字回改前；
  `win32_pts.c:2922/2930`）＋编译腿 `-DWPF_PTS_HANDLE_STRICT_REVERSE=1`（`win32_pts.c:2927`，
  **只在副本**，把收严条编掉）。

**未改**：`T-A47`（`QTP-LIVE-NARROW`）与 `T-A17`（`OOW_LIVE_GUARD`）两条既有闸**逐字保留**
（它们在“是否发 `+176`”这一层仍有意义）；收严是**多加的一道**，不是替换。

---

## §2 现取读数（**成对**；同一装置、同一流程、只差一个件）

| 面 | 改前（`so df27801beb222f05`） | 改后（`so 22e147d144b901c0`） |
|---|---|---|
| ① `[TPCL] site=RenderSimpleLines.Geom` **8 行段** `rectDV` | **`0`**（`/tmp/hc-run-103528.log`） | **`33528`**（`/tmp/hc-run-103557.log`） |
| ① **6 行段** `rectDV` | **`0`** | **`25146`** |
| ① 单行段 `rectDV` | `4191` | `4191`（不变） |
| ① **同 track 逐段 `v`** | **全 `0`**（`rectV=0` 逐段全 0 ⇒ 共 `v`） | `[FSQSPL-DVR] psub=0x… cParas=3 per_para_dvrUsed=[0:33528,1:25146,2:25146] **v_rel=[0:0,1:33528,2:58674]**` |
| ② `Unrecoverable system error` | 现场三件有（`092614`）；本装置 9 趟未现取 | **`0`** |
| ② `Handle has been already released` | 现场有 | **`0`** |
| ② `Process terminated` | 现场有 | **`0`** |
| ② 进程 `alive`／`app_rc` | `yes`／`143`（本装置） | `yes`／`143` |
| ② **收严拒发**（`stale-paraclient-across-page-destroy`） | 不存在（该判据本波新加） | **`363`** 次（`[FS_PAGE_GAP] rc=-10000` 具名行） |
| 帧 `sha16`（tab1） | `80c4290266e79edf` | `cb7567c5162b5daa` |
| 帧 `AE`（灰度，改前 vs 改后 tab1） | — | **`0`**（RGB 求差 `>10` 计 `96 px`，全在 `x=422..517 y=160` 一行＝Beige 盒上缘） |
| 症状门 | `magenta=0 colors=282 ink=847932` | `magenta=0 colors=283 ink=847932` |
| 四具名色计数（tab1） | `GhostWhite=9983 Beige=922 DarkGreen=47 LightGoldenrodYellow=5880` | **逐字相同** |

> **`v_rel` 的算法（可复算，非"现取"）**：宿主 `PtsHelper.ArrangeParaList`（`PtsHelper.Linux.cs:182-209`）
> 的 `rcPara.v = rcTrackContent.v + Σ_{k<i}(dvrUsed[k]) + dvrTopSpace[i]`；`rcTrackContent` ＝
> `FSSUBTRACKDETAILS.fsrc`，本侧声明值现取为 `[FSQSTD-SRC] … u=0 **v=0** du=768 dv=576`，
> `dvrTopSpace` 本侧恒 0 ⇒ 绝对 `v = [0, 33528, 58674]`。**native 侧观测不到托管侧的 `rcPara.v`**
> ⇒ 本行如实具名 `NOINFO=host-side-v-not-native-observable(computed-from-this-row)`。

---

## §3 验收（逐条）

1. **缺陷②**：`T-B1` 复现步骤（点 tab2 → tab3）跑 hc demo ⇒ **`rc≠134`**：`alive=yes`、日志
   `Unrecoverable system error`＝`0`、`Handle has been already released`＝`0`、`Process terminated`＝`0`
   （`/tmp/hc-run-103557.log`；另两趟 `/tmp/hc-run-103340.log`、`/tmp/hc-run-102505.log` 同形）。
   ⇒ **不 `FailFast`** ✓
   - **反极性**：见 §4-①（**未取到**，如实记 `NOINFO`）。
2. **缺陷①**：**几何成对** ✓（§2 表前五行：同 track 三段 `v = [0,33528,58674]`，改前全 0）；
   **帧面成对** ✓（`sha16 80c4290266e79edf → cb7567c5162b5daa`、`AE=0`（灰度）／`96 px`（RGB））。
   ⚠️ **但帧面无"可见改善"**：`AE` 灰度 `0`、四具名色计数逐字相同 ⇒ 本装置上**取不到**用户所述的
   "文字重叠"画面 ⇒ 该腿判 **`NOINFO`**（详见 §4-②）。
3. **`nm==exports`** ✓（`diff -q` 逐名相等，`846` 行）｜**`PTSGAP=PASS`** ✓
   （`tool=54 dead=11 artifact=1 ops=42 impl=42 so16=22e147d144b901c0 exports=846`；`PTSGAP_FRONTIER_STATE=NAMED`）｜
   **`DEFREG=PASS declared=225 route_ids=225`**（rc=0）｜**`REPORTID=PASS files=351 ids=2263 declared=225`**（rc=0）。
4. **`PTS_GUARD=PASS legs=2/2`**／**`PTS_COLORANCHOR=PASS k=24 … hits=3`** ⇒ **未回退** ✓
   （`bash build/MilBridge/tools/pts-pages-guard.sh --legs build/MilBridge/tests/PtsPagesProbe/evidence`，rc=0；
   本趟现取的 tab1 帧四色 `GhostWhite=9983 Beige=922 DarkGreen=47 LightGoldenrodYellow=5880` ⇒ `hits=3`（`>=200`））。
5. **症状门成对** ✓（§2 表末三行：`alive`／`app_rc`／`magenta`／`colors`／`ink` 无回退；`colors` `282→283`＝`+1`）。

---

## §4 具名 `NOINFO` 与边界（如实划界）

1. **`NOINFO-1`（缺陷② 反极性腿未复现）**：三条腿**均未**取到 `FailFast` ——
   · `WPF_PTS_HANDLE_STRICT=0`（`rev1`／`/tmp/hc-run-103235.log`）：`Unrecoverable=0`；
   · 副本 `-DWPF_PTS_HANDLE_STRICT_REVERSE=1`（`so ac80c5a7f5f88f84`／`rev2`／`/tmp/hc-run-103412.log`）：`Unrecoverable=0`（且该趟 `fsp_pl_epoch != page_destroy_n` **一次都没成立** ⇒ 根本没走到那条路）；
   · 与 `T-B1` §1.5 的 9 趟一致（`FailFast` 现场只在**用户 `:10`（`1728x1080`）**上出现过）。
   ⇒ **本装置不可确定性复现**（跑次敏感）⇒ 该腿记 `NOINFO`，**不拿"不死"冒充"反极性已证"**。
2. **`NOINFO-2`（缺陷① 帧面）**：`AE`（灰度）＝ `0`、四具名色计数逐字相同 ⇒ **本装置上，"流文档
   视图文字重叠"的可见画面既未取到基线、也未取到改善**；能取到的**只有段描述符层**的成对
   （`rectDV` `0→33528/25146`、`v_rel` `[0,0,0]→[0,33528,58674]`）。⇒ "用户可见重叠已消除"**未证**。
   归因（如实）：本装置缺省档下 `FsQueryTrackParaList` 的 `cParas` **恒 1**（页轨单段），
   3 段同轨只出现在 `FsQuerySubtrackParaList`（`cParas=3`，现取 `psub=0x…`，23 次），
   且 `[TPCL] rectV` 逐段仍为 `0` ⇒ 其 `index≥1` 段的 `Arrange`/`ValidateVisual` 未在帧面留痕。
3. **`NOINFO-3`（帧同类）**：`poly` 三趟（`pol1`／`pol2`／`pol3`）的 tab1 帧 `sha16` **同值**
   `cb7567c5162b5daa`；`rev2` 亦同值 ⇒ 本增量**不改变 tab1 帧**（在灰度意义上逐像素相同）。
4. **`NOINFO-4`（`so` 世代 vs 现场）**：现场三件（`092614`／`094401`／`094259`）未落 `so16` 行
   ⇒ 其跑的是否本世代件 **取不到**（不猜）；本报告只用**本席现取**的 `df27801beb222f05 → 22e147d144b901c0`。
5. **未跑**：整趟 `verify-all`（照 `T-B3` ②）、`static-jaws-check.sh`。
6. **黑名单未碰**：`build/MilBridge/tools/**`（判据件，只**调**不**改**）／`verify-all.sh`／
   `build/close-wave.sh`／`build/shims/**`／`upstream/**`／hc demo 仓外工程 —— 逐处均未写。

---

## §5 改动清单（逐文件）

| 件 | 改什么 |
|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | 缺陷①②两处（§1）；**未动**任何既有反腿旋钮的语义 |
| `src/WpfGfx.Linux.Native/bin/exports.txt` | **构建重产**（`nm -D --defined-only`，逐名不变，`846`） |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | **构建重产**（`df27801beb222f05 → 22e147d144b901c0`；`554152 B`） |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `PTSGAP-DECL` 行的 `so16:` 重锚（**只此一格**；`tool/dead/artifact/ops/impl/exports/w66pre16` 未动） |
| `docs/unimplemented.md` | `D-G70` **现值位**的 `so16` 随动（历史 `dated` 行**一字未动**） |

**未改（有意）**：`docs/ROUTES.md`／`README.md` 里的 `so16=df27801beb222f05` 全在 **`dated` 历史段**
（本仓“只增不改”纪律）⇒ 保留原文；`PTSGAP` 牙现取 `PASS`（它不抽历史行的 `so16`）。

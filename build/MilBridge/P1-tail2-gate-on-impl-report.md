# `P1-tail2` · `T-A54` · 两闸转缺省开（`WPF_PTS_FLOATER_CBK`／`WPF_PTS_TABLEOBJ`）—— `TASK-0007` 第 4 色缺省落位（**判决：判据 ① 已达 —— 缺省腿 `LightGoldenrodYellow = 1998 px ≥ 200` ∧ 缺省路径零回归（与 `T-A53` 开闸腿逐字节同）∧ 两条反极性该红必红 ∧ 门禁五件全绿**）

- **读时**：`2026-10-01T08:0x+0800`（本席现取，各条另注）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=d47d99f`（＝ `T-A53` 收尾那笔；**未换代**）。
- **改前件备份（仓外 `~/tA54-work/bak/`）**：`win32_pts.c.HEADpre`（`17b1aacb19dbfa53`，与 `git show HEAD:…` **逐位相同** ⇒ 真改前件）／`pts-gap-decl.txt.HEADpre`（`905c7b751aa62c26`）／`KNOWN-DEFECTS.md.HEADpre`（`2725ccc1aa9c8c51`）／`HANDOFF-NEXT.md.HEADpre`（`f82a3d374cd814c1`）／`libwpfwin32.so.HEADpre`（`3ff91579e7ea3efa`）。
- **写域（逐件）**：`src/WpfGfx.Linux.Native/src/win32_pts.c`（**四处**：两闸缺省常量 `0→1` ＋ 两处注释/前向声明文案随动）／`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（DECL 行 `so16` 随动 ＋ dated `T-A54` 重锚追注）／**复述位现值位**（`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 现值位 `so16` ／`build/MilBridge/HANDOFF-NEXT.md`：`§3` 新增 `T-A54` 收口行 ＋ 机器值契约 `cell=#1` 追写）／**新建载体** 本件。
- **未改**（如实体例）：`build/PresentationFramework.Linux/reapply-patches.py`（**生成器一字未动**；`sha16` 仍 `b6a3a24137a77ddf`）⇒ 其重产件亦未动（`PresentationFramework.dll` 仍 `1c6c58df6d757f3f`）—— 本增量全在 native（托管链已在 `T-A37`／`T-A52`／`T-A53` 备妥，**无需托管改动**）。
- **黑名单遵守**：未动 `build/shims/**`／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`（**含 `defect-registry-declared.tsv`** —— 故 `DEFREG_DECLDRIFT=1` 只能如实记、不能重发）／`upstream/**`（只读）；**未跑**整趟 `verify-all`；未改相位位；未 `git add/commit/push`。
- **重活**：**1 趟 native 构建**（`< 5 s`）＋ **3 趟跑器**（共 **6 条腿**；全走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- <cmd>`，逐趟 `HEAVYSLOT=RELEASED rc=0 held=4/34/37 s`）；进程只按 PID；显示位只用空闲 `:23x`（`DISPLAY_PICK :231`，逐趟 `DEVICE_REAP state=clean`）；禁 `sleep` 轮询；写前 `cp -p`；temp+rename（由只读脚本改）；模式守恒。**收尾现取**：重活槽 `SLOT=FREE`。
- **口径**：一切读数**本席现取**（`sha256sum`／`nm -D --defined-only`／`grep -c`／`bash build/MilBridge/tools/{pts-pages-guard,pts-gap-count-check,defect-registry-check,report-id-domain-check}.sh`／`python3 ~/tA15-work/selfcheck.py`／`compare -metric AE`（ImageMagick，只读）。

---

## §0 结论速览（自包含）

1. ✅ **判据 ① 已达（关键）**：**缺省腿**（两闸皆缺省开，**不设任何 env**）`k=24` 上 **`LightGoldenrodYellow = 1998 px`（≥ 200）**；`PTS_COLORANCHOR=PASS k=24 scan=GhostWhite=18945 Beige=910 DarkGreen=44 LightGoldenrodYellow=1998 hits=3 min=200`（`T-A53` 缺省腿 `hits=2` ⇒ **+1 ＝ 第 4 色**）。
2. ✅ **翻闸动作**：`WPF_PTS_FLOATER_CBK_DEFAULT`／`WPF_PTS_TABLEOBJ_DEFAULT` 由 `0` 翻为 `1`（照 `T-A28→T-A31` 体例），**仅显式 `=0` 才关**（两条反极性腿）。**导出面一字未动**、**无新增/删减 stub** ⇒ `so16` 换、**字节数不变**（`462648 B`）。
3. ✅ **缺省零回归**：缺省腿的三帧（`boot`／`k23`／`k24`）与 `T-A53` 的**开闸腿 `on4`** **逐字节相同**（`AE=0`，`sha16` 逐格相等）；症状门逐格同（`ink=480000`／`alive=yes`／`app_rc=143`／`magenta=0`／`ns=…FlowDocumentDemo`／`failfast=0`）⇒ **翻闸后的缺省路径 ≡ `T-A53` 的前沿取证腿**。
4. ✅ **反极性（该红必红，同一 `.so 642019f680d75d87`／同装置 `:231`／只差 env）**：
   - `pol0_floater`（`WPF_PTS_FLOATER_CBK=0`）⇒ **第 4 色回 `0`**，页退回**改前 3 色 baseline**（`colors=905 fr_sha=791696291d51470b`，`GhostWhite=22736`／`Beige=910`／`DarkGreen=44`）；`PTS_GUARD=PASS`（**未**变红：该腿回到**改前既有**形态，不是新红）。
   - `pol0_tableobj`（`WPF_PTS_TABLEOBJ=0`）⇒ **第 4 色回 `0`** 且无表模型 ⇒ `FsQueryTableObjDetails` **诚实拒**（`[HC-UNHANDLED]=374`）⇒ **整页空白**（`colors=383 fr_sha=ef3fd6765f18f51b`）⇒ **`PTS_COLORANCHOR=FAIL hits=0`／`PTS_GUARD=FAIL`**（**该红必红**）。
5. ✅ **门禁五件**：`nm -D --defined-only` ＝ `exports.txt` ＝ **688**（逐名 `diff` 零差异）｜`PTSGAP=PASS tool=71 dead=11 artifact=1 ops=59 impl=60 so16=642019f680d75d87 exports=688`（`rc=0`）｜`DEFREG=PASS declared=225 route_ids=225`（`rc=0`；`DECLDRIFT=1 keys=KD` **如实记**，见 §5.5）｜`REPORTID=PASS files=331 ids=2240 declared=225`（`rc=0`；本件落盘后 `+1`）｜自检面 `PtsGapSelfCheck=1`／`Diag=0`／`(2nd)=1`（幂等）。
6. 🔴 **具名下一靶（承 `T-A53` §6，未变）**：**表**单元内容**排版**（`pfnFormatCellFinite`）—— 本增量只让行背景落像素；`FsQueryTableObjRowDetails` 仍一律报 `cCells=0`（诚实的空）。

---

## §1 改动（逐处；全部在 `win32_pts.c`，附登记面/复述面随动）

### 1.1 两个闸缺省常量 `0 → 1`
- `#define WPF_PTS_FLOATER_CBK_DEFAULT 0` → **`1`**（`win32_pts.c`，`wpf_pts_floater_cbk_gate` 之前）。
- `#define WPF_PTS_TABLEOBJ_DEFAULT 0` → **`1`**（同文件，`wpf_pts_tableobj_gate` 之前）。
`T-A28→T-A31` 体例：**只翻缺省常量 ＋ 随动注释**；`getenv` 分支与语义**一字未动**。

### 1.2 注释/前向声明文案随动（三处，**不碰逻辑**）
- `HANDOFF`-无关的前向声明：`⏪ T-A52：Floater 内容排版驱动的运行期闸（缺省关…）` ⇒ `⏪ T-A52／T-A54：…（T-A54 起**缺省开**…）`。
- `wpf_pts_format_one_para` 的 Floater 支内注释：`（闸 WPF_PTS_TABLEOBJ 缺省关 ⇒ 缺省路径不动）` ⇒ `（T-A54 起闸 WPF_PTS_TABLEOBJ **缺省开**）`。
- 两闸定义块件头：`（缺省 **关**）` ⇒ `（T-A54 起缺省 **开**）` ＋ 各补一段 `⏪ T-A54` 翻闸理由（承 `T-A52`／`T-A53` 的当年缺省关现场依据 ＝ 已由 `T-A53` 解除；闸：显式 `=0` 才关）。

### 1.3 登记面 `pts-gap-decl.txt`
DECL 行 `so16=3ff91579e7ea3efa` → **`so16=642019f680d75d87`**；其下**只增**一段 `⚠️ 波 T-A54 重锚` 追注（照 `T-A31` 重锚体例）：述翻闸、`so16` 换代、字节数不变、`tool/dead/artifact/ops/impl` 全未动、翻闸理由。

### 1.4 复述位现值位（只读改数；**无新增 D-G 编号**）
- `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（`T-A47` dated 现值位块）：`so16=3ff91579e7ea3efa` → **`so16=642019f680d75d87`**（`tool/ops/impl` 未动 ⇒ 该件复述位无其它随动）。
- `build/MilBridge/HANDOFF-NEXT.md`：`§3` **只增**一行 `T-A54` 收口记录（承 `T-A52` 行）；文件尾**只增**一行机器值契约 `cell=#1`（`inputs_fp` 现取 `5ec42660…`，因写域件 `win32_pts.c`／`pts-gap-decl.txt` **在覆盖面内** ⇒ 必然位移）。

### 1.5 为什么**不是**改生成器
本轮**一个字节都没碰** `reapply-patches.py` 与其重产件 —— 本增量只翻 native 侧两个运行期闸缺省。

---

## §2 成对读数（**同一 `.so 642019f680d75d87`／同一 `pf 1c6c58df6d757f3f`／同装置 `:231`／同批工具**；证据 `~/tA54-work/legs/{default,pol0_floater,pol0_tableobj}`；三趟 `LEGS_RUNNER=PASS requested=2 obtained=2 refused=0`）

| 腿 | env | 证据目录 |
|---|---|---|
| `default` | **（不设任何 env：两闸皆缺省开）** | `~/tA54-work/legs/default/` |
| `pol0_floater` | `WPF_PTS_FLOATER_CBK=0` | `~/tA54-work/legs/pol0_floater/` |
| `pol0_tableobj` | `WPF_PTS_TABLEOBJ=0` | `~/tA54-work/legs/pol0_tableobj/` |

### 2.1 逐腿现取计数（`grep -c`，`app_g1.log`）

| 量 | **`default`（缺省）** | `pol0_floater` | `pol0_tableobj` |
|---|---|---|---|
| `[FSFLOATER-CBK]` | **2** | 0 | 2 |
| `[FSFLOATER-CONTENT]` | **2** | 0 | 2 |
| `[FSTABLEOBJ-CBK]` | **2** | 0 | 0 |
| `[FSTABLEOBJ-DRV]` | **2**（`nrows=5 built=1 v=TABLE-MODEL-BUILT`） | 0 | 0 |
| `[FSTABLEOBJ-ROW]` | **10**（2 窗 × 5 行） | 0 | 0 |
| `[FSTABLEOBJ-AUTOFIT]` | **2**（`AUTOFIT-ON-REAL-CLIENT`） | 0 | 0 |
| `[FSTABLEOBJ-Q]` | **8921**（`ok`） | 0 | 0 |
| `entry point named` | **0** | 0 | 0 |
| `[HC-UNHANDLED]` | **0** | 0 | **374**（`PtsException '-10000'` ＝ `no-table-model` 的**诚实拒**） |
| `app_g1.log` 行数 | 71116 | 59466 | 15436 |

（缺省腿的 `[FSTABLEOBJ-DRV]`／`[FSTABLEOBJ-Q]` 行文与 `T-A53` 开闸腿同形；`[FSTABLEOBJ-CBK] rc=0 … slots=45 … out=WRITTEN bytes=360`／`[FSFLOATER-CBK] rc=0 … slots=16 … out=WRITTEN bytes=128`。）

### 2.2 帧面（逐腿现取：`leg_*.env` ＋ `sha256sum`）

| 腿 | `alive` | `app_rc` | `magenta` | `colors`(k24) | `ink` | `ns`(k24) | `k24` `fr_sha` | `k23` `fr_sha` | `boot` `fr_sha` | `k24` `fr_ae_boot` |
|---|---|---|---|---|---|---|---|---|---|---|
| **`default`** | yes | 143 | 0 | **910** | 480000 | `…FlowDocumentDemo` | **`64603fc1d8e23e39`** | `10d0b9d54e649c10` | `b21eb530afd3c66c` | 220019 |
| `pol0_floater` | yes | 143 | 0 | **905** | 480000 | 同 | `791696291d51470b` | `10d0b9d54e649c10` | `b21eb530afd3c66c` | 220019 |
| `pol0_tableobj` | yes | 143 | 0 | **383** | 480000 | 同 | `ef3fd6765f18f51b`（空态参照成员） | `10d0b9d54e649c10` | `b21eb530afd3c66c` | 15386 |

**帧差（本席自算，`compare -metric AE`，只读 PNG）**：`AE(boot_default, boot_poltable)=0`、`AE(k23_default, k23_poltable)=0`、`AE(k24_default, k24_polfloater)=3791`、`AE(k24_default, k24_poltable)=210578` ⇒ 两极的差**只落在被闸控的那一页**（`k23`／`boot` 逐字节同值）。

### 2.3 缺省零回归 —— 与 `T-A53` **开闸腿 `on4`** 逐帧对拍（本席自算）

| 帧 | `AE(tA54_default, tA53_on4)` | `sha16`（两腿） |
|---|---|---|
| `boot` | **0** | `b21eb530afd3c66c` |
| `k23` | **0** | `10d0b9d54e649c10` |
| `k24` | **0** | `64603fc1d8e23e39` |

⇒ 缺省腿（翻闸后）与 `T-A53` 的前沿取证腿**逐字节同一世界**；症状门逐格同（§2.2）。**除第 4 色外的既有读数逐格不变**（允许的位移**逐条具名记账**，见 §5.1）。

### 2.4 帧面四色锚（**本席自算／判据件现取**；锚集 `GhostWhite=248,248,255`／`Beige=245,245,220`／`DarkGreen=0,100,0`／`LightGoldenrodYellow=250,250,210`；`LightGray` **不入集**）

| 帧 | 腿 | `GhostWhite` | `Beige` | `DarkGreen` | **`LightGoldenrodYellow`** | `ncolors` |
|---|---|---|---|---|---|---|
| `boot` | 三腿同值 | 0 | 0 | 0 | **0** | 386 |
| **`k24`** | **`default`** | **18945** | **910** | **44** | **1998**（**≥200**） | **910** |
| `k24` | `pol0_floater` | 22736 | 910 | 44 | **0**（反极） | 905 |
| `k24` | `pol0_tableobj` | 0 | 0 | 0 | **0**（反极／空白） | 383 |
| `k23` | 三腿同值 | 0 | 0 | 0 | 0 | 636 |

### 2.5 判据件读数（`pts-pages-guard.sh --legs`；纯读、零 `dotnet`）

```
# default（缺省 = 两闸皆开）
PTS_COLORANCHOR=PASS k=24 scan=GhostWhite=18945 Beige=910 DarkGreen=44 LightGoldenrodYellow=1998 hits=3 min=200 base=…all-0 phase=realized
PTS_ENFE=PASS total=0 by_name=none allow=none non_allow=none phase=realized log=…/default/app_g1.log log_sha16=4134fa0de440e5ce
PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=leg23-colors-out-of-band=636 direction=in-file phase=realized
PTS_G10_NAME=PASS observed=FsQueryTextDetails names=18 roster=24 …
# pol0_floater（WPF_PTS_FLOATER_CBK=0）
PTS_COLORANCHOR=PASS k=24 scan=GhostWhite=22736 Beige=910 DarkGreen=44 LightGoldenrodYellow=0 hits=2 min=200 …
PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=leg23-colors-out-of-band=636 direction=in-file phase=realized
# pol0_tableobj（WPF_PTS_TABLEOBJ=0）
COLOR-ANCHOR-ABSENT k=24 expect>=200px&hits>=2 measured=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 hits=0 …
PTS_COLORANCHOR=FAIL k=24 scan=…all-0… hits=0 expect_min=200 expect_hits=2 … reason=declared-color-anchor-absent
PTS_GUARD=FAIL legs=2/2 fails=leg24-n1-frame-unestablished(frame-identity(sha16=ef3fd6765f18f51b∈{…})),leg24-color-anchor-absent(hits=0<2,…) … phase=realized
```

### 2.6 门禁五件（现取）

| 门 | 读数 | rc |
|---|---|---|
| `nm==exports` | `nm -D --defined-only` ＝ **688** ＝ `exports.txt` 行数；**逐名 `diff` 零差异** | 0 |
| `PTSGAP` | `PASS tool=71 dead=11 artifact=1 ops=59 impl=60 so16=642019f680d75d87 exports=688` | 0 |
| `DEFREG` | `PASS declared=225 route_ids=225`（`DECLDRIFT=1 keys=KD`，**非门禁诊断行**，见 §5.5） | 0 |
| `REPORTID` | `PASS files=331 ids=2240 declared=225`（本件**落盘前** 331 ⇒ 落盘后 332，`+1` 即本件） | 0 |
| 自检面 | `PtsGapSelfCheck=1`／`Diag=0`／`(2nd)=1`（幂等） | — |

---

## §3 逐件 `sha16`（现取）

| 件 | 改前 | 改后 |
|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `17b1aacb19dbfa53` | **`a40e5b86bdfa0011`** |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `3ff91579e7ea3efa`（462648 B） | **`642019f680d75d87`**（462648 B，**字节数不变**） |
| `src/WpfGfx.Linux.Native/bin/exports.txt`（**非仓内件**） | `c7a1298c812e4e31` | **未变**（688 行） |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `905c7b751aa62c26` | **`d000c8c41565e7fa`** |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `2725ccc1aa9c8c51` | **`b8b2c5cd445d5692`** |
| `build/MilBridge/HANDOFF-NEXT.md` | `f82a3d374cd814c1` | **`0eb0dfc7d682e4b6`** |
| `build/PresentationFramework.Linux/reapply-patches.py`（生成器） | `b6a3a24137a77ddf` | **未变** |
| `build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` | `1c6c58df6d757f3f` | **未变** |

---

## §4 断点逐跳（从 `T-A53` 的具名收口到本趟）

| 跳 | 件:行（内容锚） | 现取 |
|---|---|---|
| ① `T-A53` 收口靶 | `P1-tail2-tableobj-impl-report.md` §6：`WPF_PTS_FLOATER_CBK`／`WPF_PTS_TABLEOBJ` 的**缺省翻转** | **本趟落地** |
| ② 翻缺省常量 | `win32_pts.c` `WPF_PTS_*_DEFAULT 0→1` | ✅ 缺省腿 `PTS_COLORANCHOR=PASS hits=3`（第 4 色 1998px） |
| ③ 零回归 | 缺省腿 ↔ `T-A53` 开闸腿 `on4` | ✅ 三帧 `AE=0`／症状门逐格同 |
| ④ 反极性 | 显式 `=0` 两腿 | ✅ 第 4 色回 0（一腿退 baseline、一腿空白并 `PTS_GUARD=FAIL`） |

---

## §5 诚实边界（防读宽，逐条）

1. **允许的位移逐条记账（缺省零回归的具名清单）** —— 翻闸后缺省腿 vs **改前缺省**（`T-A53` `off2`）的**全部**位移，**只此三条**（其余逐格不变）：
   - `colors 905→910`（第 4 色成片 ⇒ 色数 +5）—— 允许（新增色）。
   - `k24 fr_sha 791696291d51470b→64603fc1d8e23e39`（`k24` 帧像素变）—— 允许（新增色落像素）。**`k23`／`boot` 帧 `sha16` 逐字不变**。
   - `GhostWhite 22736→18945`（−3791 px，＝ `k24` 的 `AE`）—— 允许（表行背景替换了该区域的既有底色）；`Beige=910`／`DarkGreen=44` **未动**；`ink=480000`／`alive`／`app_rc`／`magenta`／`ns` **逐格未动**。
2. **"四具名色全 ≥200px" 的如实口径**：缺省腿 `k24` 四具名色**都出现**（`GhostWhite=18945`／`Beige=910`／`DarkGreen=44`／`LightGoldenrodYellow=1998`），但 **`DarkGreen=44 px < 200`**（**改前既有**读数，`T-A52`／`T-A53` 各腿与 baseline 均 `44`，本增量**未动**）⇒ `PTS_COLORANCHOR hits=3`（＝ `T-A53` 缺省腿 `hits=2` **＋ 1 枚第 4 色**），**顶到本锚集在 `min=200` 下可判别的上限**（判据件 `COLOR_ANCHOR_K24` 只登记 4 色、阈值 `COLOR_ANCHOR_MIN=200`）。⇒ 判据 ① 的 `hits` 取**如实口径 `3`**；**不**声称 `hits=4`。
3. **反极 `pol0_floater` 的 `PTS_GUARD` 不红**（`hits=2`）：该腿**回到改前既有 3 色形态**（`colors=905 fr_sha=791696291d51470b`），它是 `T-A52` 之前的**正常页**，不是"红灯页"。判据 ② 要求的"该红"＝**第 4 色计数回 `0`**（本腿满足）；**另**一腿 `pol0_tableobj` 才是**整页空白**的**红**（`PTS_GUARD=FAIL`）。两条如实并列，**不**把 `pol0_floater` 的"退回 baseline"冒充成"新红"。
4. **只让"行背景"落像素，未排单元内容**（承 `T-A53` §5.1）：`LightGoldenrodYellow` 是 `TableRow Background`（行层）；`FsQueryTableObjRowDetails` 仍一律报 `cCells=0`、`FsQueryTableObjCellList` 恒空 ⇒ **不**证"表单元文本已绘出"。行内文本/单元几何**不在本增量射程**（具名下一靶，§6）。
5. **`DEFREG_DECLDRIFT=1 keys=KD`（如实记，非门禁）**：本趟改了 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（复述位**现值位** `so16` 随动）⇒ 该 route 件 `sha16` 离开 `defect-registry-declared.tsv` 的 `DECL-ANCHORS KD=`；而 `defect-registry-declared.tsv` 在**黑名单** `build/MilBridge/tools/**` 内 ⇒ **本席未重发**（`--emit`）⇒ 该诊断行留 `1`。`DEFREG=PASS`／`rc=0`（该行是**非门禁诊断**，判据件自身注明）。**未**改判据逻辑、**未**改声明件。
6. **`bin/exports.txt` 非仓内件**：`src/WpfGfx.Linux.Native/bin/` 在 `.gitignore:24` ⇒ 该件由 `build-shim.sh --symbols` **每次重产**；`nm==exports` 是**构建不变量**（不是"我们手工对齐了一份表"）。本增量导出面**零变化** ⇒ 该件 `sha16` **未变**。
7. **`pol0_tableobj` 的 `[HC-UNHANDLED]=374` 是**反极性腿**的**有意红**（`no-table-model` 的诚实拒），**不是**缺省路径症状；缺省（`default`）与 `pol0_floater` 两腿 `[HC-UNHANDLED]=0`、`entry point named=0`。
8. **`HANDOFF-NEXT.md` 的机器值 `cell=#1`**：本波写域件 `win32_pts.c`／`pts-gap-decl.txt` **在覆盖面内** ⇒ `inputs_fp` 位移，现取 `5ec42660…`（与 `T-A53` 的 `fd46f73b…` 成对）；复述位现值位（`docs/ROUTES.md`／`README.md`／`docs/unimplemented.md`／`samples/…/KNOWN-DEFECTS.md`／本件）**不在覆盖面内**。

---

## §6 遗留（下一增量具名靶，承 `T-A53` §6 未变）

- **表**单元内容**排版**：调 `pfnFormatCellFinite`（槽 20）为每个单元真造内容子页，并把 `FSTABLEROWPROPS.cCells`／`FsQueryTableObjRowDetails.cCells`／`FsQueryTableObjCellList` 填成**真值** ⇒ 表内文本落像素。
- **行高改由单元高派生**（取代本侧 `NOINFO=row-height-self-convention` 下界约定）。

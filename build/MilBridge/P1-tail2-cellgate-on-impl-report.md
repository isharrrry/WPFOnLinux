# `P1-tail2` · `T-A57` · 表单元闸转缺省开（`WPF_PTS_TABLECELL`）—— 实现报告（**判决：判据 ① 已达 —— 缺省腿（`WPF_PTS_TABLECELL` 缺省开）单元内容真落像素（`LightGoldenrodYellow 1998→5830 px`、表区 `dark(<140) +1449 px`）∧ 缺省腿与 `T-A56` 开闸腿**逐字节同** ∧ 缺省零回归 ∧ 门禁全绿 ∧ 反极性（`=0`）单元内容回缺**）

- **读时**：`2026-10-01T11:2x–11:3x+0800`（本席现取，各条另注）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=6a85187`（＝ `T-A56` 收尾那笔；**未换代**）。
- **改前件备份（仓外 `~/tA57-work/bak/`，`cp -p`，取在**任何写之前**）**：`win32_pts.c`（`3727a8df1399a337`）／`pts-gap-decl.txt`（`491d439b4e509450`）／`KNOWN-DEFECTS.md`（`b867c2eac90dde81`）／`HANDOFF-NEXT.md`（`8310a724d3192d2a`）／`ROUTES.md`（`8e29067012871734`）／`README.md`（`3415d52fad3cba90`）／`unimplemented.md`（`fdb221d64f8b8b69`）／`win32_classification.c`（`74b5247e5ee6c4d0`）。后四件本趟**逐字节未改**（只在备份时取，作「不在覆盖面/未动」的对拍基线）。
- **写域（逐件）**：`src/WpfGfx.Linux.Native/src/win32_pts.c`（**一处常量 ＋ 一段注释**）／`tools/pts-gap-decl.txt`（DECL 行 `so16` ＋ dated `T-A57` 重锚追注）／**复述位现值位**（`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 两处现值位 `so16` ＋ `T-A52..A56` 段末追 `T-A57` 归因；`build/MilBridge/HANDOFF-NEXT.md`：`§3` 新增 `T-A57` 收口行 ＋ 文件尾机器值契约 `cell=#1` 追写）／**新建载体** 本件。
- **未改**（如实体例）：`build/PresentationFramework.Linux/reapply-patches.py`（**生成器一字未动**；`sha16` 仍 `b6a3a24137a77ddf`）⇒ 其重产件亦未动（`PresentationFramework.dll` 仍 `1c6c58df6d757f3f`）—— 本增量全在 native（托管链 `T-A56` 已备，**无需托管改动**）。`docs/ROUTES.md`／`README.md`／`docs/unimplemented.md`／`win32_classification.c` 的现值位数字（`58`／`59`／`70`）本趟**未动**（`tool/ops/impl/exports` 全未变）。
- **黑名单遵守**：未动 `build/shims/**`／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`（**只读跑**判据件）／`upstream/**`（只读）；**未跑**整趟 `verify-all`；未改相位位；未 `git add/commit/push`。
- **重活**：**1 趟 native 构建**（`< 5 s`）＋ **3 趟跑器**（共 **6 条腿**；全走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- <cmd>`，逐趟 `HEAVYSLOT=RELEASED rc=0`）；进程只按 PID；显示位只用空闲 `:23x`（`DISPLAY_PICK :231`，逐趟 `DEVICE_REAP state=clean`）；禁 `sleep` 轮询；写前 `cp -p`；temp+rename；模式守恒。**收尾现取**：重活槽 `SLOT=FREE`。
- **口径**：一切读数**本席现取**（`sha256sum`／`nm -D --defined-only`／`grep -c`／只读 `python3`＋`PIL` 解 PNG／只读 `python3` 自算 `AE`／`bash build/MilBridge/tools/{pts-pages-guard,pts-gap-count-check,defect-registry-check,report-id-domain-check,handoff-machine-values-check}.sh`／`bash ~/w153a/bin/infp.sh`）。

---

## §0 结论速览（自包含）

1. ✅ **判据 ① 已达（关键）**：**缺省腿**（不设任何 env：`WPF_PTS_TABLECELL` 已缺省开）`k=24` 的**表区**（`x410..750,y150..250`）里 `dark(<140)` 像素 **`2869 → 4318`（+1449）**（其中新 goldenrod 行带 `y181..234` 内 **`1735 → 2958`（+1223）**、第 1 行带 `y153..181` 内 **`262 → 486`（+224）**）；`colors 910 → 1220`、`LightGoldenrodYellow 1998 → 5830`；`PTS_GUARD=PASS`、`PTS_COLORANCHOR=PASS k=24 hits=3`。**与 `T-A56` 开闸腿 `cell1` 逐帧 `AE=0`**（缺省腿即 `T-A56` 的前沿取证腿）。
2. ✅ **翻闸动作**：`WPF_PTS_TABLECELL_DEFAULT` 由 `0` 翻为 `1`（照 `T-A28→T-A31` 体例），**仅显式 `=0` 才关**（反极性腿）。**导出面一字未动**、**无新增/删减 stub** ⇒ `so16` 换、**字节数不变**（`467240 B`）。
3. ✅ **缺省零回归**：缺省腿三帧（`boot`／`k23`／`k24`）与 `T-A56` 的**开闸腿 `cell1`** **逐字节相同**（`AE=0`，`sha16` 逐格相等）；反极腿 `pol0` 与 `T-A56` 的**改前缺省腿 `default2`** **逐字节相同**（`AE=0`）；症状门逐格同（`ink=480000`／`alive=yes`／`app_rc=143`／`magenta=0`／`ns=…FlowDocumentDemo`／`[HC-UNHANDLED]=0`／`entry point named=0`）。
4. ✅ **反极性（该红必红，同一 `.so d406f243cdc2c402`／同装置 `:231`／只差 env）**：`WPF_PTS_TABLECELL=0`（`pol0`）⇒ **单元内容回缺**：`[FSTABLECELL] v=CELL-SUBPAGE` **16 → 0**、`[FS_CLRUPD]` **2000 → 0**、表区 `dark(<140)` **4318 → 2869**、`LightGoldenrodYellow` **5830 → 1998**、`k24 fr_sha 0bdb2dfd05952bc9 → 64603fc1d8e23e39`（＝ `T-A56` 改前缺省）。
5. ✅ **门禁五件**：`nm -D --defined-only` ＝ `exports.txt` ＝ **689**（逐名 `diff` 零差异）｜`PTSGAP=PASS tool=70 dead=11 artifact=1 ops=58 impl=59 so16=d406f243cdc2c402 exports=689`（`rc=0`）｜`DEFREG=PASS declared=225 route_ids=225`（`rc=0`；`DECLDRIFT=1 keys=KD` **如实记**，见 §5.5）｜`REPORTID=PASS`（`rc=0`）｜`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0`（`rc=0`）。
6. 🔴 **具名下一靶（承 `T-A56` §6，未变）**：**行高与单元高的自洽** ＋ **单元边界面**（`fskboundaryAbove/Below`／`dvrAbove/Below`）—— 本趟只翻闸缺省，未触及该两项（`T-A56` §5 的诚实边界原样成立）。

---

## §0.5 方案（本趟**单方案**，照 `T-A54` 体例；未做多方案试探）

| 方案 | 形态 | 现取读数 | 判决 |
|---|---|---|---|
| **1** | 只翻缺省常量 `0→1` ＋ 闸定义块注释随动（`getenv` 分支与语义一字未动） | 缺省腿 `[FSTABLECELL] v=CELL-SUBPAGE ×16`／`PTS_COLORANCHOR=PASS hits=3`／`k24 fr_sha=0bdb2dfd05952bc9`（＝ `T-A56` 开闸腿）；反极腿回改前缺省 | ✅ **达** |

> 「翻闸」是**收口步**（承 `T-A56` §6 的具名靶），不是新能力：`T-A56` 已把单元内容排版落地并给开闸腿读数；本趟只把该行为放进缺省路径并证零回归。**故无「方案 2／3」**（上限 3、未用满，如实记）。

---

## §1 断点逐跳（从 `T-A56` 的具名前沿到本趟）

| 跳 | 件:行（内容锚） | 现取 |
|---|---|---|
| ① `T-A56` 的具名前沿 | `P1-tail2-cellcontent-impl-report.md` §6：**`WPF_PTS_TABLECELL` 的缺省翻转**（当行高/边界面落地且无回归后按 `T-A28→T-A31` 体例翻缺省） | 本趟落地 |
| ② 翻缺省常量 | `win32_pts.c` `WPF_PTS_TABLECELL_DEFAULT 0→1` | ✅ 缺省腿 `PTS_COLORANCHOR=PASS hits=3`（`LightGoldenrodYellow=5830px`） |
| ③ 零回归 | 缺省腿 ↔ `T-A56` 开闸腿 `cell1` | ✅ 三帧 `AE=0`／症状门逐格同 |
| ④ 反极性 | `WPF_PTS_TABLECELL=0` | ✅ 单元内容回缺（`[FSTABLECELL]=0`、`LGY 5830→1998`） |

⇒ `T-A56` 的收口靶（**`WPF_PTS_TABLECELL` 的缺省翻转**）**在本趟解**；表单元内容**缺省路径即落像素**。

---

## §2 改动（逐处）

### 2.1 闸缺省常量 `0 → 1`（`win32_pts.c`）
```c
#ifndef WPF_PTS_TABLECELL_DEFAULT
#define WPF_PTS_TABLECELL_DEFAULT 1      /* T-A57 前为 0 */
#endif
```
`T-A28→T-A31` 体例：**只翻缺省常量 ＋ 随动注释**；`wpf_pts_tablecell_gate()` 的 `getenv` 分支与语义**一字未动**（`=0` 仍关）。

### 2.2 注释随动（同一块，**不碰逻辑**）
闸定义块件头 `（`T-A53`／`T-A54` 体例；**缺省关**）` ⇒ `（`T-A57` 起缺省 **开**）`；原「为什么**缺省关**（硬边界：「新增 ⇒ 缺省关」）」段替换为 `⏪ T-A57` 翻闸理由（承 `T-A56` 已解除的现场依据：开闸腿 `LightGoldenrodYellow 1998→5830 px`、表区 `dark(<140) +1449 px`）；闸语义句改为 `显式 `WPF_PTS_TABLECELL=0` ⇒ 关（**反极性腿**）；缺省 `1` ⇒ 开`。

### 2.3 登记面 `pts-gap-decl.txt`
DECL 行 `so16=193e20c8b483ea3d` → **`so16=d406f243cdc2c402`**；其下**只增**一段 `⚠️ 波 T-A57 重锚` 追注（照 `T-A54`／`T-A56` 重锚体例）：述翻闸、`so16` 换代、字节数不变、`tool/dead/artifact/ops/impl` 全未动、翻闸理由、判据 ① 成对读数。

### 2.4 复述位现值位（只读改数）
- `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`：**两处**「现值，现取」块的 `so16=193e20c8b483ea3d` → **`so16=d406f243cdc2c402`**（`tool/ops/impl/exports` 未动 ⇒ 其余格逐字不变）；`T-A52..A54` 段的**逐增量归因**行末尾**只增** `；T-A57（翻 `WPF_PTS_TABLECELL` 为缺省开 ⇒ **表单元内容进缺省路径**：…）五位未动，`so16→d406f243cdc2c402``。
- `build/MilBridge/HANDOFF-NEXT.md`：`§3` **只增**一行 `T-A57` 收口记录（承 `T-A54` 行）；文件尾**只增**一行机器值契约 `cell=#1`（`inputs_fp` 现取 `42fac2a8…`，因写域件 `win32_pts.c`／`pts-gap-decl.txt` **在覆盖面内** ⇒ 必然位移）。
- ⚠️ **未动**：`docs/ROUTES.md`（`TASK-0302` 行 `58/59`）／`README.md`／`docs/unimplemented.md`／`win32_classification.c` —— 它们承载的是 **`tool/ops/impl` 口径数**，本趟**全未变**，故**不需随动**（逐件 `sha16` 与改前相等，见 §4）。**历史 dated 行原文保留**。

### 2.5 为什么**不是**改生成器
本轮**一个字节都没碰** `reapply-patches.py` 与其重产件 —— 本增量只翻 native 侧一个运行期闸缺省（托管链 `T-A56` 已备妥）。

---

## §3 成对读数（**同一 `.so d406f243cdc2c402`／同一 `pf 1c6c58df6d757f3f`／同装置 `:231`／同批工具**；证据 `~/tA57-work/legs/{default,pol0,cell1}`，三趟 `LEGS_RUNNER=PASS requested=2 obtained=2 refused=0`）

| 腿 | env | 证据目录 |
|---|---|---|
| `default` | **（不设任何 env：`WPF_PTS_TABLECELL` 缺省开）** | `~/tA57-work/legs/default/` |
| `pol0`（新闸反极） | `WPF_PTS_TABLECELL=0` | `~/tA57-work/legs/pol0/` |
| `cell1`（显式开） | `WPF_PTS_TABLECELL=1` | `~/tA57-work/legs/cell1/` |

### 3.1 逐腿现取计数（`grep -c`，`app_g1.log`；与 `T-A56` 腿并排）

| 量 | **`default`（缺省）** | `pol0` | `cell1` | `T-A56 default2`（改前缺省） | `T-A56 cell1`（开闸腿） | `T-A56 pol0` |
|---|---|---|---|---|---|---|
| `[FSTABLEOBJ-CBK]` | **2** | 2 | 2 | 2 | 2 | 2 |
| `[FSTABLEOBJ-DRV]` | **2** | 2 | 2 | 2 | 2 | 2 |
| `[FSTABLECELL] … v=CELL-SUBPAGE` | **16** | **0** | **16** | 0 | **16** | 0 |
| `[FSTABLEOBJ-ROW]` | **10** | 10 | 10 | 10 | 10 | 10 |
| `[FSTABLEOBJ-Q]` | **11960** | 7956 | 11535 | 9111 | 10965 | 8606 |
| `FS_CLRUPD` | **2000** | **0** | 1928 | 0 | 1832 | 0 |
| `FS_PAGE_GAP` | **0** | 0 | 0 | 0 | 0 | 0 |
| `[HC-UNHANDLED]` | **0** | 0 | 0 | 0 | 0 | 0 |
| `entry point named` | **0** | 0 | 0 | 0 | 0 | 0 |

> ⚠️ **`[FSTABLEOBJ-Q]`／`FS_CLRUPD` 的逐趟可变性（如实记）**：这是**查询/重绘次数类**计数，随运行时序波动（`default 11960` ≢ `cell1 11535`，两腿帧面却**逐字节同**）⇒ **帧面才是权威**；`v=CELL-SUBPAGE` 计数（`16`）与两态可分性（`0`）**逐腿稳定**，是承重量。**不得**把 `[FSTABLEOBJ-Q]` 的抖动读成回归。

### 3.2 帧面（逐腿现取：`sha256sum` ＋ 只读 PNG）

| 腿 | `alive` | `app_rc` | `magenta` | `colors`(k24) | `ink` | `ns`(k24) | `k24` `fr_sha` | `k23` `fr_sha` | `boot` `fr_sha` |
|---|---|---|---|---|---|---|---|---|---|
| **`default`** | yes | 143 | 0 | **1220** | 480000 | `…FlowDocumentDemo` | **`0bdb2dfd05952bc9`** | `10d0b9d54e649c10` | `b21eb530afd3c66c` |
| `pol0` | yes | 143 | 0 | **910** | 480000 | 同 | `64603fc1d8e23e39` | `10d0b9d54e649c10` | `b21eb530afd3c66c` |
| `cell1` | yes | 143 | 0 | **1220** | 480000 | 同 | `0bdb2dfd05952bc9` | `10d0b9d54e649c10` | `b21eb530afd3c66c` |

**帧差（本席自算，只读 PNG）**：`AE(default_k24, pol0_k24)=15831`（＝单元内容位移）；`AE(default_k24, cell1_k24)=0`；`AE(default_k23, pol0_k23)=0`、`AE(default_boot, pol0_boot)=0`、`AE(default_k23, cell1_k23)=0`、`AE(default_boot, cell1_boot)=0` ⇒ 位移**只落在被闸控的那一页 `k24`**。

### 3.3 缺省零回归 —— 与 `T-A56` 腿**逐帧对拍**（本席自算，只读 PNG）

| 对拍 | `boot` | `k23` | `k24` |
|---|---|---|---|
| `AE(tA57_default, tA56_cell1)`（开闸腿） | **0** | **0** | **0** |
| `AE(tA57_cell1, tA56_cell1)` | **0** | **0** | **0** |
| `AE(tA57_pol0, tA56_default2)`（改前缺省） | **0** | **0** | **0** |
| `AE(tA57_pol0, tA56_pol0)` | **0** | **0** | **0** |
| `AE(tA57_default, tA56_default2)`（改前缺省） | **0** | **0** | **15831** |

⇒ ① **翻闸后的缺省腿 ≡ `T-A56` 的前沿取证腿 `cell1`**（逐字节同一世界）；② **反极腿 ≡ `T-A56` 改前缺省腿 `default2`**（逐字节同一世界）；③ `default` ↔ `default2` 的**唯一**位移在 `k24`（`AE=15831`）＝新增的**表单元内容**（允许位移，逐条具名见 §5.1）。`boot`／`k23` 两帧**三腿全跨代 `AE=0`**。

### 3.4 帧面四色锚 ＋ 单元文本像素（**本席自算**，只读 PNG；锚集 `GhostWhite=248,248,255`／`Beige=245,245,220`／`DarkGreen=0,100,0`／`LightGoldenrodYellow=250,250,210`）

| 帧 | 腿 | `GhostWhite` | `Beige` | `DarkGreen` | `LightGoldenrodYellow` | `ncolors` |
|---|---|---|---|---|---|---|
| `k24` | `T-A56 default2`（改前缺省） | 18945 | 910 | 44 | 1998 | 910 |
| **`k24`** | **`default`（缺省）** | **9794** | **910** | **44** | **5830** | **1220** |
| `k24` | `pol0`（反极） | **18945** | **910** | **44** | **1998** | **910** |
| `k24` | `cell1` | 9794 | 910 | 44 | 5830 | 1220 |
| `boot` | 三腿同值 | 0 | 0 | 0 | 0 | 386 |
| `k23` | 三腿同值 | 0 | 0 | 0 | 0 | 636 |

**单元文本像素（本席自算；判据①的承重读数）**：

| 区（`k24`，`x410..750`） | `default` | `pol0`（反极） | `T-A56 default2` | 位移（`pol0→default`） |
|---|---|---|---|---|
| 新 goldenrod 行带 `y181..234` 的 `dark(<140)` | **2958** | 1735 | 1735 | **+1223** |
| 第 1 行带 `y153..181` 的 `dark(<140)` | **486** | 262 | 262 | **+224** |
| 整表区 `y150..250` 的 `dark(<140)` | **4318** | 2869 | 2869 | **+1449** |

> ⚠️ **归因（逐条）**：`GhostWhite↓`（18945→9794）／`LightGoldenrodYellow↑`（1998→5830）／`colors↑`（910→1220）三条 ⇒ **表单元内容（含行高由单元内容高派生）落像素**；`dark(<140) +1449` ⇒ **单元内文本真绘**（`T-A56` 同源读数，本趟在**缺省路径**复现）。**不许**把"空白"读成绿：缺省腿三帧均可与 `T-A56` 开闸腿对拍（§3.3）。

### 3.5 判据件读数（`pts-pages-guard.sh --legs`；纯读、零 `dotnet`）

```
# default（缺省 = WPF_PTS_TABLECELL 开）
PTS_COLORANCHOR=PASS k=24 scan=GhostWhite=9794 Beige=910 DarkGreen=44 LightGoldenrodYellow=5830 hits=3 min=200 base=…all-0 phase=realized
PTS_ENFE=PASS total=0 by_name=none allow=none non_allow=none phase=realized log=…/default/app_g1.log log_sha16=565558dcaf6d5152
PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=leg24-colors-out-of-band=1220,leg23-colors-out-of-band=636 direction=in-file phase=realized
PTS_G10_NAME=PASS observed=FsQueryTextDetails names=20 roster=24 …
# pol0（WPF_PTS_TABLECELL=0）
PTS_COLORANCHOR=PASS k=24 scan=GhostWhite=18945 Beige=910 DarkGreen=44 LightGoldenrodYellow=1998 hits=3 min=200 …
PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=leg23-colors-out-of-band=636 direction=in-file phase=realized
# cell1（WPF_PTS_TABLECELL=1）
PTS_COLORANCHOR=PASS k=24 scan=GhostWhite=9794 Beige=910 DarkGreen=44 LightGoldenrodYellow=5830 hits=3 …
PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=leg24-colors-out-of-band=1220,leg23-colors-out-of-band=636 direction=in-file phase=realized
```

### 3.6 门禁五件（现取）

| 门 | 读数 | rc |
|---|---|---|
| `nm==exports` | `nm -D --defined-only` ＝ **689** ＝ `exports.txt` 行数；**逐名 `diff` 零差异** | 0 |
| `PTSGAP` | `PASS tool=70 dead=11 artifact=1 ops=58 impl=59 so16=d406f243cdc2c402 exports=689` | 0 |
| `DEFREG` | `PASS declared=225 route_ids=225`（`DECLDRIFT=1 keys=KD`：复述位件已随动，**`declared.tsv --emit` 落在黑名单 `build/MilBridge/tools/**` ⇒ 未重发**，如实记） | 0 |
| `REPORTID` | `PASS files=334 ids=2242 declared=225`（本件落盘前 `334` ⇒ 落盘后 `335`，`+1` 即本件） | 0 |
| `HANDOFF_MV` | `PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0`（本趟追写 `T-A57` 收口行 ＋ `cell=#1` 机器值） | 0 |

---

## §4 逐件 `sha16`（现取）

| 件 | 改前 | 改后 |
|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `3727a8df1399a337` | **`1eb3408fc4567d53`** |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `193e20c8b483ea3d`（467240 B） | **`d406f243cdc2c402`**（467240 B，**字节数不变**） |
| `src/WpfGfx.Linux.Native/bin/exports.txt`（**非仓内件**） | `005b16e0cd5b95b2`（689 行） | **未变**（689 行） |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `491d439b4e509450` | **`94ecbd53b08d3885`** |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `b867c2eac90dde81` | **`48f5f5030518b132`** |
| `build/MilBridge/HANDOFF-NEXT.md` | `8310a724d3192d2a` | **`6ae41477306cd1d0`** |
| `docs/ROUTES.md` | `8e29067012871734` | **未变** |
| `README.md` | `3415d52fad3cba90` | **未变** |
| `docs/unimplemented.md` | `fdb221d64f8b8b69` | **未变** |
| `src/WpfGfx.Linux.Native/src/win32_classification.c` | `74b5247e5ee6c4d0` | **未变** |
| `build/PresentationFramework.Linux/reapply-patches.py`（生成器） | `b6a3a24137a77ddf` | **未变** |
| `build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` | `1c6c58df6d757f3f` | **未变** |

---

## §5 诚实边界（防读宽，逐条）

1. **允许的位移逐条记账（缺省零回归的具名清单）** —— 翻闸后缺省腿 vs **改前缺省**（`T-A56` `default2`）的**全部**位移，**只此三条**（其余逐格不变）：
   - `colors 910→1220`（单元内容成片 ⇒ 色数 +310）。
   - `k24 fr_sha 64603fc1d8e23e39→0bdb2dfd05952bc9`（`k24` 帧像素变，`AE=15831`）—— 允许（单元内容落像素）。**`k23`／`boot` 帧 `sha16` 逐字不变**。
   - `GhostWhite 18945→9794`（−9151 px，≈`k24` 的 `AE`）／`LightGoldenrodYellow 1998→5830`（+3832 px）—— 允许（表单元内容/行带替换该区域既有底色）；`Beige=910`／`DarkGreen=44` **未动**；`ink=480000`／`alive`／`app_rc`／`magenta`／`ns` **逐格未动**。
2. **反极腿的 `PTS_GUARD` 不红**（`pol0`）：该腿**回到改前既有缺省形态**（`colors=910 fr_sha=64603fc1d8e23e39`），它是 `T-A56` 之前的**正常页**，不是"红灯页"。判据 ② 要求的"该红"＝**单元内容计数回缺**（`[FSTABLECELL] 16→0`、`LGY 5830→1998`、表区 `dark 4318→2869`）；本腿满足。本条如实并列，**不**把"退回改前缺省"冒充成"新红"。
3. **"单元内容落像素"只证"表区里多出 1449 px 深色（<140）像素 ＋ `LightGoldenrodYellow` 增 3832 px"，不证"与上游 PTS 的排印完全一致"**（承 `T-A56` §5.1）：本侧单元内容走**本侧** `FsCreateSubpageFinite` ＋ 本侧行台账；行高、断开、行距皆为**本侧派生**。**不**声称 ABI/几何与上游可比。
4. **本趟未触及 `T-A56` §5 的两项真实缺口**：① 行高只是"内容子页高"的**本侧派生**；② `FSTABLEROWDETAILS.fskboundaryAbove/Below` 仍恒报 `Outer`、`dvrAbove/Below=0`（未按真实行边界填）。⇒ 分页/断行场景**未验证**（本页是有限窗、不跨页）。翻闸**只**把 `T-A56` 已验证的开闸行为放进缺省路径。
5. **`DEFREG_DECLDRIFT=1 keys=KD`（如实记，非门禁）**：本趟改了 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（复述位**现值位** `so16` 随动）⇒ 该 route 件 `sha16` 离开 `defect-registry-declared.tsv` 的 `DECL-ANCHORS KD=`；而 `defect-registry-declared.tsv` 在**黑名单** `build/MilBridge/tools/**` 内 ⇒ **本席未重发**（`--emit`）⇒ 该诊断行留 `1`。`DEFREG=PASS`／`rc=0`（该行是**非门禁诊断**，判据件自身注明）。**未**改判据逻辑、**未**改声明件。
6. **`bin/exports.txt` 非仓内件**：`src/WpfGfx.Linux.Native/bin/` 在 `.gitignore` ⇒ 该件由 `build-shim.sh --symbols` **每次重产**；`nm==exports` 是**构建不变量**（不是"我们手工对齐了一份表"）。本增量导出面**零变化** ⇒ 该件 `sha16` **未变**。
7. **`[FSTABLEOBJ-Q]`／`FS_CLRUPD` 的逐趟抖动**（见 §3.1 注）是**查询/重绘次数**类，非回归征兆；`v=CELL-SUBPAGE` 计数与两态可分性**逐腿稳定**。本席**不**把帧面逐字节相同的两腿之间的计数差读成回归。
8. **`HANDOFF-NEXT.md` 的机器值 `cell=#1`**：本波写域件 `win32_pts.c`／`pts-gap-decl.txt` **在覆盖面内** ⇒ `inputs_fp` 位移，现取 `42fac2a8…`（与 `T-A56` 的 `34a38de7…` 成对）；复述位现值位（`docs/ROUTES.md`／`README.md`／`docs/unimplemented.md`／`samples/…/KNOWN-DEFECTS.md`／本件）**不在覆盖面内**。

---

## §6 遗留（下一增量具名靶，承 `T-A56` §6 未变）

- **行高与单元高的自洽**：现取行高由 `max(单元内容高)` 定；`dvrAboveRow/dvrBelowRow` 的**归属**（本侧今天是"加在行高里、单元矩形＝行高"）须写清并与上游语义对齐。
- **单元边界面**：`FsQueryTableObjRowDetails` 的 `fskboundaryAbove/Below` ＋ `dvrAbove/Below` 按**真实行边界**（首/末行 `Outer`、断行 `Break`、行间 `Inner`）填；`fForcedRow` 按 `FSKROWHEIGHTRESTRICTION` 派生。
- **`SSC`／`declared.tsv` 的收波随动**：由不在本任务黑名单内的收波步骤完成。

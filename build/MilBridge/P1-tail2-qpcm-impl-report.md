# P1-tail2 `TASK-0302` · native「查询期内容模型」（`NATIVE-QUERY-PHASE-CONTENT-MODEL`）—— 实现报告（`T-A25`）

- **读时**：`2026-09-30T14:3x–14:4x+0800`（本席现取）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=fb0c7f5`（`T-A24` 新线侦察落地后；现取）。
- **现件代**：`src/WpfGfx.Linux.Native/bin/libwpfwin32.so` ＝ **`744fb3affd107bf0`**（425640 B；改前 **`e09c8d739c179966`**／421296 B）；`bin/exports.txt` ＝ **674** 行（**一字未动**，`nm` 逐名对拍零差异）。
- **件指纹（现取；`sha256` 前 16 位）**：`src/WpfGfx.Linux.Native/src/win32_pts.c`＝**`a799e9f0f94e7ea4`**（改前 `74aa285b641de4a6`）｜`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`＝**`0b024313f968ddb9`**（改前 `a1a4cd69582e9498`，`so16` 重锚）。
- **改前件备份（仓外）**：`~/tA25-work/win32_pts.c.74aa285b.bak`／`libwpfwin32.so.e09c8d739c179966.bak`／`pts-gap-decl.txt.bak`。
- **只改两件**：`src/WpfGfx.Linux.Native/src/win32_pts.c`（本增量本体）＋ `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（声明行 `so16` 重锚，`D-G70` 形态）＋ `docs/ROUTES.md`（dated 链，只增不改）。**导出面一字未动** ⇒ 其余复述位（`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/HANDOFF-NEXT.md`／`src/**/win32_classification.c`）**无随动需要**（`ops`／`impl`／`tool` 三字段未动 ⇒ `PTSGAP=PASS` 零 `SITE-DRIFT`）。
- **黑名单遵守**：未动 `build/*.Linux/**`／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`；未跑整趟 `verify-all`；重活（构建 ＋ 三条腿）全走 `bash ~/heavy-slot.sh`（`--min-avail 2500 --max-hold 1800 --wait 3600`）；进程只按 PID；写前 `cp -p` 备份。
- **行号纪律**：本件行号**仅本次有效**（内容锚原文一并给出）。

---

## §0 结论速览（自包含）

1. **增量已落地（三处 ＋ 一处自检）**：
   **(甲)** 窗内**递归建子树** `wpf_pts_sub_enum_into`（对每个枚举出的子段再以它为 `nms` 调 `+136`／`+144`，深度上界 `WPF_PTS_SUB_MAX_DEPTH=8`）；
   **(乙)** `FsQuerySubtrackParaList` 的 `pfspara` 由**托管段句柄**改为**本侧自有子段对象**的字段地址（承 `FsQueryTrackDetails` 范式）；
   **(丙)** `wpf_pts_sub_destroy` 扩为**整棵子树**递归回收（`DestroyDocContext` 同步回收未过继的子对象）；
   **(丁)** 新增 `[SUBTREE-SELFTEST] mask=0x1f`（正腿 ＋ **两条反极性必红**）。
2. **`unclaimable-*` 归零（成对）**：`reason=unclaimable-subtrack` **341→0**｜`reason=unclaimable-para` **54→0**（改前 → 改后，同跑器／相邻代／同一显示流程）。
3. **异常面大幅下降**：`did not complete formatting operation` ＝ `[HC-UNHANDLED]` **399→113**。余下 **113** 条**全部改制名**：`[FS_PAGE_GAP] reason=no-text-line-model` **109** ＋ `reason=null-subtrack` **4**（`psub=(nil)`，与改前同型）。
4. **内容模型在查询期**可答出**：`[FSQSTD] rc=0` **508→724**（`rc≠0` **345→4**）｜`[FSQSPL] rc=0` **508→724**（`rc≠0` 恒 **0**）｜`[PROVCLAIM]` **397→0**（改前那条"认出身份但仍无内容模型"的中间态，已被"交回可认领对象"取代）｜`[SUBTREE]` **0→3**（`nodes_total` 累计 13、`fail=0`、`depth_max=1`）。
5. **帧面零位移（如实报红）**：三帧 `fr_sha` 恒 `ef3fd6765f18f51b`（**逐字节相同**）；`AE(boot,k24)=15386`、`bbox=(28,169,239,560)`（**全在左栏 ListBox 区**）、**内容区 `AE(x>240)=0`**；具名色锚 `GhostWhite/Beige/DarkGreen/LightGoldenrodYellow` 全 **0**。⇒ **`D1`/`D3`/`D4` 仍红、`D2` 绿**；**两页仍空白**。
6. **剩余阻塞具名（非本增量射程）**：`FSTEXTDETAILS` **文本行模型** —— `FsQueryLineListSingle`／`FsQueryLineListComposite`／`FsQueryLineCompositeElementList` **均未导出**（现取 `exports.txt` 零命中）⇒ 修好子段内容模型后，绘制路径**前进一层**（容器开始展开子段），但**叶段落**（`TextParaClient`）在 `FsQueryTextDetails` 处**诚实拒绝**（`no-text-line-model`）⇒ 这是**下一个独立增量**。
7. **门禁**：`PTSGAP=PASS`（rc=0、零 `SITE-DRIFT`）｜`DEFREG=PASS`（rc=0）｜`REPORTID=PASS`（rc=0）｜`nm==exports`（674==674、逐名零差异）。**症状门六项与改前逐字相同**（`alive=yes/app_rc=143/magenta=0/colors=383/ink=480000/ns`；`guard` 「`[HC-UNHANDLED]` 计数」187/377→27/92）。

---

## §1 设计口径 ＋ 实现落点（`win32_pts.c`）

### 1.1 为什么（逐条有现取证据）

| # | 现取事实（改前腿 `~/tA25-work/evidence-before/app_g1.log`） | 它要求什么 |
|---|---|---|
| a | `[FSQSTD] rc=-10000 reason=unclaimable-subtrack` **341** 条，其 `psub` **全部 ＝ `0x4`**（托管段句柄） | 交出去的 `pfspara` 是**托管句柄** ⇒ 回问时 `wpf_pts_sub_claim` **认不出** |
| b | `[FS_PAGE_GAP] reason=unclaimable-para entry=FsQueryTextDetails` **54** 条，`para` 亦 **`0x4`** | 同上（同一批子段句柄） |
| c | `[SUBENUM] … cparas=3 ok=1 v=ENUM-OK` ×3；`[SUBTREE]`＝0 | 子段序**只在窗内**可得（`+136` 窗外 `-100002`）⇒ 必须**窗内建、查询期读** |
| d | `[PROVCLAIM]` 397 条里 **395 是 `claim=none`**（2 条 `claim=prov`） | 来源证据**救不了**主链（会话／doc 一变即失效）⇒ 必须**按对象身份**认领 |

### 1.2 落点（逐处）

| 落点 | 内容 |
|---|---|
| `wpf_pts_subtrack` 结构 | 新增 `child_objs[WPF_PTS_SUB_CHILD_MAX]`（与 `children[]` **一一对应**）／`depth`／`obj_no` |
| `WPF_PTS_SUB_MAX` | **16→512**（窗内建树 ⇒ 一个容器一个对象＋每子段一个对象；满表 ⇒ 调用方**拒绝交回**） |
| `WPF_PTS_SUB_MAX_DEPTH` | 新增 ＝ **8**（递归深度上界，到界即**不再往下建**） |
| `wpf_pts_sub_new` | 记 `obj_no`（诊断用）；行为不变 |
| `wpf_pts_sub_destroy` | **递归**销毁 `child_objs[]`（先子后己）—— 否则子对象成**活条目泄漏** |
| `wpf_pts_sub_enum_into`（新） | 把某容器的子段序枚举进 `obj`；为每个子段建对象并**递归**（口径承 `wpf_pts_sub_enum`：只在窗内／只用回调真返回／穷尽才算成功／有界／成环守卫） |
| `wpf_pts_sub_enum` | 层 1 枚举成功后，**同趟**建子树并存 `d->sub_child_objs[]` ＋ 具名 `[SUBTREE]` 行 |
| `wpf_pts_doc` | 新增 `sub_child_objs[]`／`sub_child_objs_n`／`sub_child_objs_fail` |
| `FsQueryTrackParaList` | 建 `dp->sub` 时把 `d->sub_child_objs[]` **过继**给 `dp->sub->child_objs[]`（所有权转移，`d->sub_child_objs[k]=NULL` ⇒ **不双销**） |
| `FsQuerySubtrackParaList` | ① 新增**承重前置**：任 `child_objs[i]` 缺失 ⇒ 具名 `reason=no-child-object` **拒绝整个填充**（**绝不**退回托管句柄／**绝不**伪造指针）；② `rg[i].pfspara = wpf_pts_sub_handle(obj->child_objs[i])`（`nmp` 仍＝该子段的托管句柄，用于 `+176`） |
| `DestroyDocContext` | 除 `dp->sub` 的**递归**销毁外，同步回收**未过继**的 `sub_child_objs[]` |
| `wpf_pts_subtree_selftest`（新） | 每进程一次，`[SUBTREE-SELFTEST]`（见 §2.2） |
| `FsQuerySubtrackDetails`／`FsQueryTextDetails` | **一字未改** —— 它们本就按 `wpf_pts_sub_claim` 认领；改的是"交出去的是什么" |

**🔴 无假值／无假成功**（硬边界逐条）：① 出参只写**回调真返回**的东西（`c_paras`＝窗内枚举计数）；② 交回的 `pfspara` 是**本侧对象字段地址**（可身份校验；NULL／栈地址／外来值**必被拒**）；③ 子对象建不成 ⇒ **拒绝交回**并具名（`no-child-object`），**不是**退回托管句柄；④ `FsQueryTextDetails` **无成功分支**（文本行模型本侧无源）⇒ **恒返 `-10000` ＋ 出参一字不写**（只把判词从 `unclaimable-para` 移到 `no-text-line-model`）。

---

## §2 成对机读读数（改后腿现取，逐字）

### 2.1 窗内建树（`[SUBTREE]` ×3）

```
[SUBTREE] where=FsCreatePageBottomless root=0x3 n_children=3 child_objs=3 fail=0 nodes_total=6 depth_max=1 live=6 created=12 depth_lim=8 v=IN-WINDOW-SUBTREE-BUILT
[SUBTREE] where=FsCreatePageFinite     root=0x3 n_children=3 child_objs=3 fail=0 nodes_total=12 depth_max=1 live=13 created=19 depth_lim=8 v=IN-WINDOW-SUBTREE-BUILT
[SUBTREE] where=FsCreatePageBottomless root=0x3 n_children=1 child_objs=1 fail=0 nodes_total=13 depth_max=1 live=15 created=21 depth_lim=8 v=IN-WINDOW-SUBTREE-BUILT
```

口径：**3 个 doc 各驱一窗**（`drive_done`），每窗建一棵子树；`fail=0`（无子对象建不成）；`depth_max=1` ⇒ 本页容器结构**浅**（根 3 子段，各带 1 个叶）；枚举到叶段时 `+136` 返 `-100002`（非 `ISegment`）⇒ 该对象 `enum_ok=0`（**不冒充** cParas）。

### 2.2 谓词自检（`[SUBTREE-SELFTEST]`，与 `wpf_pts_sub_selftest`／`wpf_pts_prov_selftest` 同形制）

```
[SUBTREE-SELFTEST] mask=0x1f child_claimable=1 stub_handle_rejected=1 missing_child_rejected=1 destroy_recursive=1 live_restored=1 live=0 created=6 v=SUBTREE-IDENTITY-OK(5/5)（反极性两类必红：托管段句柄不可认领／缺子对象不得退回）
```

- **bit0 正腿**：子对象句柄**可**从台账认领（托管回问 `FsQuerySubtrackDetails(child)` 可过）；
- **bit1 反腿（改前形态）**：**托管段句柄 `0x4` 不可认领** ⇒ 这正是改前 `unclaimable-subtrack` 的**来源**，该红必红；
- **bit2 反腿（`P8` 陷阱）**：`c_paras=1` 而**缺** `child_objs[0]` ⇒ 交回时**必须拒**（不得退回托管句柄）；
- **bit3**：销毁父 ⇒ 子**递归**离册（不再可认领）；**bit4**：在册数复原（无泄漏）。

### 2.3 主链成对（改前腿 vs 改后腿）

| 行／面 | 改前（`.so e09c8d739c179966`） | 改后（`.so 744fb3affd107bf0`） |
|---|---|---|
| `reason=unclaimable-subtrack` | **341** | **0** |
| `reason=unclaimable-para` | **54** | **0** |
| `[HC-UNHANDLED]`／`did not complete formatting operation` | **399** | **113**（`no-text-line-model` 109 ＋ `null-subtrack` 4） |
| `[FSQSTD] rc=0` ｜ `rc≠0` | 508 ｜ 345 | **724** ｜ **4** |
| `[FSQSPL] rc=0` ｜ `rc≠0` | 508 ｜ 0 | **724** ｜ 0 |
| `[PROVCLAIM]` | 397（`claim=prov` 2／`claim=none` 395） | **0** |
| `[SUBENUM]`／`ENUM-OK` | 3／3 | 3／3 |
| `[SUBTREE]` | 0 | **3** |
| `reason=no-text-line-model` | 0 | **109** |
| `[FSPARALIST-FILL]` | 510 | 337 |
| `[DRIVE-PROBE2-OOW]` | **0**（`T-A22` 起窗外零回调） | **0** |

> ⚠️ **射程**（照 `P9`）：`[FSPARALIST-FILL]`／`[FSPARALIST-CONSUME]`／`[DRIVE-PROBE3-OOW]` 等**由托管侧调用次数**驱动（native 不决定其次序与次数），**不是**本改动的判定面。**本改动的判定面** ＝ `unclaimable-* 341/54→0`、`[FSQSTD]/[FSQSPL] rc=0 508→724`、`[PROVCLAIM] 397→0`、`[SUBTREE] 0→3`、`[HC-UNHANDLED] 399→113` —— 这些**只由本改动决定**。

---

## §3 验收逐条（可计算；`A24 §4` 的 4 条判据 D1–D4）

### ① D1–D4 逐条现取读数 ＋ 反极性

| # | 判据（可证伪单行式） | 现取读数（改前 → 改后） | 判 |
|---|---|---|---|
| **D1** | `grep -c 'did not complete formatting operation'` ＝ 0 | **399 → 113** | 🔴 **未归零**（红） |
| **D2** | `unclaimable-para`＝0 ∧ `unclaimable-subtrack`＝0；`reason=ok` 行 `out=WRITTEN ∧ bytes>0 ∧ cParas>0` | **341/54 → 0/0**；`[FSQSTD] rc=0` 724 行全 `out=WRITTEN bytes=40 cParas>0`（`true_cParas=` 逐行给出枚举真值） | 🟢 **绿** |
| **D3** | `AE(boot,k24)` 的差异**落在内容区**（`bbox ⊄ [28,240]×[166,555]`） | `AE=15386`、`bbox=(28,169,239,560)`（**全在 ListBox 区**）、**内容区 `AE(x>240)=0`** | 🔴 **红** |
| **D4** | 具名色锚各 ≥200px **或** `y∈[40,86] ∧ x∈[258,790]` 暗像素 >0 | `GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0`；该带暗像素（`<150`）**两趟同值 6** | 🔴 **红** |

**反极性（该红必红）**：
- **D2 的必红腿（跑过，副本产物，`rc=134`）**：见 §4。
- **D1／D3／D4 的必红腿**：**净腿本趟即为红**（D1 例外面 113≠0；D3 内容区零位移；D4 色锚全 0）⇒ 判据**没有把空白读成绿**。D1 的"假成功"副本腿（把认不出改成 `rc=0` 而**出参一字不写**，期望 `out=WRITTEN bytes=0 cParas=0` 必红）**本趟未跑** —— 具名 `NOINFO-fsqstd-fake-success-leg-not-run`。

### ② 关键：`unclaimable-para`／`unclaimable-subtrack` 成对 ＋ `[HC-UNHANDLED]`／`PtsException` 成对

`341/54 → 0/0`（见 §2.3）；`[HC-UNHANDLED]`／`PtsException` **399 → 113**（**成对**：改前 399 行 100% 为 `PtsException`；改后 113 行仍 100% 为 `PtsException`，但**判词全改制名**为 `no-text-line-model`）。

### ③ 帧面成对（**不把空白读成绿**）

| 面 | 改前 | 改后 |
|---|---|---|
| `boot.png` `sha16` | `b21eb530afd3c66c` | **同**（逐字节相同） |
| `k24.png` `sha16` | `ef3fd6765f18f51b` | **同** |
| `k23.png` `sha16` | `ef3fd6765f18f51b` | **同**（`AE(k23,k24)=0`） |
| `AE(boot,k24)`／`bbox` | 15386／`(28,169,239,560)` | **同** |
| **内容区 `AE(x>240)`** | **0** | **0** |
| 色锚（`GhostWhite/Beige/DarkGreen/LightGoldenrodYellow`） | 0/0/0/0 | **0/0/0/0** |

⇒ **两页内容区没有出现任何非空态像素**（改前后**逐字节相同**）；本件**明确判红**，并**不以"占位图在场"或"帧没变"读成绿**。

### ④ 导出面／门禁

- `nm -D --defined-only bin/libwpfwin32.so | wc -l` ＝ **674** ＝ `wc -l bin/exports.txt`；**逐名对拍零差异**（无消失、无新增）；`git diff` 对 `bin/exports.txt` **零改动**。
- `PTSGAP=PASS tool=85 dead=11 artifact=1 ops=73 impl=76 so16=744fb3affd107bf0 exports=674`（rc=0、零 `SITE-DRIFT`；唯一随动字段＝`so16`）。
- `DEFREG=PASS declared=225 route_ids=225`（rc=0）。
- `REPORTID=PASS files=311 ids=2219 declared=225`（rc=0）。

### ⑤ 症状门成对（同一跑器 `run-pts-pages-legs.sh`、相邻代、同一显示流程）

| 面 | 改前（`e09c8d739c179966`） | 改后（`744fb3affd107bf0`） |
|---|---|---|
| leg24 `alive`／`app_rc` | `yes`／`143` | `yes`／`143` |
| leg24 `magenta`／`colors`／`ink` | `0`／`383`／`480000` | **同** |
| leg24 `ns`／`fr_sha` | `…FlowDocumentDemo`／`ef3fd6765f18f51b` | **同** |
| leg23 `alive`／`app_rc`／`magenta`／`colors`／`ink`／`ns`／`fr_sha` | `yes`／`143`／`0`／`383`／`480000`／`…RichTextBoxDemo`／`ef3fd6765f18f51b` | **同** |
| `guard`（＝`[HC-UNHANDLED]` 计数，k24/k23） | `187`／`377` | **`27`／`92`** |
| `fatal`／`unh` | `0`／`0` | `0`／`0` |
| `LEGS_RUNNER` | `PASS requested=2 obtained=2 refused=0` | **同** |

同趟自检：`[HCOUNTLEDGER] pair=distinct … PAIR-DISTINCT-AND-SELF-CONSISTENT`｜`[FSPARALIST-SUB-SELFTEST] mask=0x1f`｜`[PROV-SELFTEST] mask=0x1f`｜`[SUBTREE-SELFTEST] mask=0x1f`。

---

## §4 反极性（副本产物的必红腿）

**腿**：副本 `.so`（`sha16=83c60085ebb4e558`，同一源码 ＋ `-DWPF_PTS_SUB_CPARAS_FAKE=2` ⇒ `FsQuerySubtrackDetails` 写**恒定 `cParas=0`**），经 `$DLLS/A.*` ＋ `PTS_GUARD_ARM_FROM_DLLS=1` 装配（**主链产物一字未动**）。

```
[FSQSTD] rc=0 reason=ok … out=WRITTEN bytes=40 cParas=0 true_cParas=3 nms=0x2 src=SUBENUM(+136/+144)   ×35
[FSQSPL]（本趟 0 条：cParas=0 ⇒ 托管走 ContainerParaClient.cs:66 的"空子轨"支 ⇒ 嵌套内容**根本没被枚举**）
[HC-UNHANDLED] 0 条 ｜ [FS_PAGE_GAP] 0 条
CLICK k=24 alive=no … guard=0 fatal=2 unh=0 ｜ APP_RC=134（FailFast）
FailFast 位点：MS.Internal.PtsHost.PtsHost.CreateParaclient → get_PtsContext
FRAME k=24 fr_sha=2a60a00fc582e97d ｜ AE(boot,k24)=480000（整窗消失）
```

⇒ **该红必红**（两条独立证据）：① 机械面 **`cParas=0 ≠ true_cParas=3`**（`P8` 恒绿陷阱**当场可见**）；② 行为面 **`[HC-UNHANDLED]=0`** 会把这一趟读成"最干净"，**而应用 `FailFast`（`rc=134`）、帧整窗消失** ⇒ 证明「**只看 `[HC-UNHANDLED]` 归零**」**不足以**判绿，必须用 `true_cParas` 对拍。

⚠️ **装置如实记**：该腿的 runner 因**跑腿期间件被换**（`post_shim=83c60085ebb4e558 ≠ auth=744fb3affd107bf0`）而判 `LEGS_RUNNER=NOINFO reason=app-swapped-during-run`（`device=NOINFO`）—— 这是**装配口径**的如实拒绝，**不是**样本崩溃被当读数；原始 `app_g1.log` 已镜像到 `~/tA25-work/evidence-revleg/`（逐字可读）。

---

## §5 边界 · `NOINFO` · 主动披露

1. **未改任何其它仓内文件**；`git status --porcelain` 现取 ＝ `M src/WpfGfx.Linux.Native/src/win32_pts.c`／`M src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`／`M docs/ROUTES.md` ＋ 一项**先于本件**的 untracked（`build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log`）。
2. **`NOINFO-fsqstd-fake-success-leg-not-run`**：D1 的"假成功"副本腿（`rc=0` ＋ 出参一字不写 ⇒ 期望 `out=WRITTEN bytes=0 cParas=0` 必红）**本趟未跑**（跑的是 D2 的 `cParas=0` 必红腿）。现有机制：`WPF_PTS_SUB_CPARAS_FAKE`（`0`／`1`／`2`）＋ `[FSQSTD] … true_cParas=` 对拍字段。
3. **`NOINFO-text-line-model-depth`**：本件**只**证明"子段内容模型"这一层已经可认领；**没有**任何读数证明"文本行模型可得"。`FsQueryTextDetails` 的 `FSTEXTDETAILS`（`Pts.cs:1486-1498`）＋ 其下游 `FsQueryLineListSingle`／`…Composite`／`…CompositeElementList`（`Pts.cs:3756/:3764/:3772`）**均未导出** ⇒ 需**另一次独立增量**（且需行几何源）。
4. **`NOINFO-subtrack-para-geometry`（照旧在场）**：`FsQuerySubtrackParaList` 的 `dvrUsed`／`dvrTopSpace`／`bbox` 本侧**无几何源** ⇒ 保持 `memset` 后的 **0**（**不自造几何**）。⚠️ 这**意味着**：即使子段内容模型通了，`PtsHelper.ArrangeParaList` 里 `rcPara.dv = dvrUsed − dvrTopSpace = 0` ⇒ 子段矩形零高 ⇒ **像素不会因此出现**。本件**据此**判定"帧面零位移"是**可解释的**（两处 blocker 叠加），**不是**"改了没用"。
5. **射程**：本增量是**具名增量**（`T-A24` §5.1 选靶），**不是**"两页能画"。**合法终点判定**：内容模型层**已落地且可判绿（D2）**；`D1`/`D3`/`D4` 的剩余缺口**具名**为**文本行模型**（§5-3）＋ **子段几何源**（§5-4），二者**各自独立、均需另派**。
6. **未做**：未跑整趟 `verify-all`；未跑 `static-jaws-check.sh`；未判相位；未动任何牙本体；未 `git add/commit/push`。
7. **代际**：`.so`＝`744fb3affd107bf0`；`win32_pts.c`＝`a799e9f0f94e7ea4`；`pts-gap-decl.txt`＝`0b024313f968ddb9`；改前 `e09c8d739c179966`／`74aa285b641de4a6`／`a1a4cd69582e9498`。
8. **副作用物（仓外）**：`~/tA25-work/`（改前/改后/副本反腿三条腿证据 ＋ 备份件 ＋ 副本 `.so`）｜`~/w67-work/app`（已刷成改后权威件，`SYNC-APPLOCAL=PASS drift=0`）｜`/tmp/tA25fake/`（副本构建中间物）。`~/w67-work/dlls/A.*` 装配后被**逐件还原**（`fc60c34d51fd9247`／`cbd1884faeb4837e`）。

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-qpcm-impl-report.md | sha256sum | cut -c1-16`）= `34cdffca5fee1004`

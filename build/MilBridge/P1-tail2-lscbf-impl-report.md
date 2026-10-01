# `P1-tail2` · `T-A68` · **LS 回调面（第二条回调面）**（`PRECOND-NEW-CALLBACK-FACE`：28 槽／最小 9 槽）—— 实现报告

**判决**：本侧在 `LoCreateContext`（`TextFormatterContext.cs:113`）**窗内值化** `LsContextInfo`（前 744 B）＋ `LscbkRedefined`（24 B），登记 **28 槽**（最小入站面 `LS-CB-M1` **9 槽**），落**逐槽只读探针** ＋ **一条真发调通路**（显式闸 `WPF_PTS_LSCBF_INVOKE`，**缺省关**）＋ **两极化自检**。**真腿现取**：`[LSCBF] rx=OK … slots=28 nonzero=26 min_nonzero=8/9 redef_nonzero=3 layok=1 state=VALUE` **×3** ⇒ 托管冷启里**真交付回调面 3 次**，且本侧按**算出**偏移读回与托管置值（`version=4`／`cJustPriorityLim=3`／`wchTab=9`）**三锚全中**（`layok=1`）⇒ **布局假设在真数据上自证**。两极化 `[LSCBF-SELFTEST] mask=0x0f`（4/4）；探针闸开 ⇒ 桩被真调（`stub_calls 0→1`／`invokes=1`／`rc=0x7777`）、闸关 ⇒ **必拒**。**零回归**（两腿两帧逐字节同 `AE=0`；`PTS_GUARD=PASS`／`PTS_COLORANCHOR=PASS k=24 hits=3`）。**导出面**：`exports 727→747`（逐名 **+20**、**无消失**），`nm==exports`；`PTSGAP`／`DEFREG`／`REPORTID`／`HANDOFF_MV` rc=0。🔴 **如实划界**：28 槽**全为入站面**（本侧**不是作者**，`P1-ls-callback-face-recon.md` §5.1）；`InlineFormat`／`InlineDraw` 两槽**不在两入参结构内** ⇒ 本侧**不取、不冒充**。本条只判「**面已在链上 ∧ 本侧可逐槽现取 ∧ 本侧可发调**」，**不**判「内容层落地」。

- **读时**：`2026-10-01T23:0x–23:2x+0800`（本席现取；各条另注）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`（**未 `git add/commit/push`**）。
- **改前件备份（仓外 `~/tA68-work/bak/`，`cp -p`，取在**任何写之前**）**：`win32_pts.c`（`11a3f6ba49f3f22c`／703908 B）／`bin/libwpfwin32.so`（`3118bd1ce7d9604c`／503336 B）／`bin/exports.txt`（`d925266b9acd9847`／727 行）／`tools/pts-gap-decl.txt`（`e19699dbe4c9766b`／586 行）。
- **写域（逐件）**：`src/WpfGfx.Linux.Native/src/win32_pts.c`（**加一段 `T-A68` 块**（值化镜像＋28 槽登记表＋值化助手＋真发调＋只读桥接＋两极化自检）；`LoCreateContext` 内**加一行**值化调用；`wpf_pts_loc` 结构**加字段**）／`src/WpfGfx.Linux.Native/bin/exports.txt`（**构建重产**，非手改）／`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（DECL 行 `so16`／`exports` 跟权威件换 ＋ 只增一段 `T-A68` 重锚）／**复述位现值位**（`docs/ROUTES.md` `TASK-0307` 行加一条 dated 结账；`build/MilBridge/HANDOFF-NEXT.md` 文件尾机器值契约 `cell=#1／#3` 追写）／**新建载体** 本件。
- **未改**（如实体例）：`build/PresentationFramework.Linux/reapply-patches.py`（生成器**一字未动**——本增量**全在 native**，**零托管改动**）；`docs/WAVE66-PREREGISTRATION.md`（冻证据 `w66pre16=bf6b683d94549087` 未动）；`src/WpfGfx.Linux.Native/bin/libwpfwin32.so`／`bin/exports.txt` 属**非仓内件**（`.gitignore`，由 `build-shim.sh --symbols` 重产）。
- **黑名单遵守**：未动 `build/MilBridge/tools/**`（**只读跑**判据件）／`verify-all.sh`／`build/close-wave.sh`／`build/shims/**`／`upstream/**`（只读）；**未跑**整趟 `verify-all`；未改相位位；未 `git add/commit/push`。
- **重活**：**2 趟 native 构建**（改后 1 ＋ 补口 1）＋ **2 趟跑器**（`before`／`after`，各 2 条腿），全走 `bash ~/heavy-slot.sh --min-avail 2000 --max-hold 600 --wait 3600 -- <cmd>`（逐趟 `HEAVYSLOT=RELEASED rc=0`）；进程只按 PID；显示位只用跑器自分配的号（`DISPLAY_PICK :231`）；写前 `cp -p`；`temp+rename`；模式守恒。
- **口径**：一切读数**本席现取**（`sha256sum`／`nm -D --defined-only`／`diff`／`grep -c`／`dlopen` 探针（`gcc` 编译的 `~/tA68-work/probe`）／只读跑 `bash build/MilBridge/tools/{pts-gap-count-check,pts-pages-guard,defect-registry-check,report-id-domain-check,handoff-machine-values-check}.sh`）。凡引他件处一并标注。

---

## §0 结论速览（自包含）

1. ✅ **LS 回调面已在链上（本侧现取）**：`LoCreateContext` 每次被托管调用，本侧在**调用期内**把 `LscbkRedefined`（24 B）＋ `LsContextInfo` 前 744 B **逐字节值拷贝**进该上下文对象。真腿现取 `[LSCBF] rx=OK … nonzero=26 min_nonzero=8/9 redef_nonzero=3 layok=1 state=VALUE` **×3**（=3 次 `TextFormatterContext.Init()`）。
2. ✅ **布局在真数据上自证**（**非恒真**）：托管 `TextFormatterContext.cs:51/60/65` 对三处**真置值**（`version=4`@+0／`cJustPriorityLim=3`@+20／`wchTab='\u0009'=9`@+32）；本侧读回**全中**（`layok=1`）⇒ 本侧镜像算出的偏移（含 26 个回调指针槽）与真托管结构一致。**证伪条件**：任一偏移错 ⇒ 该组不等 ⇒ `layok=0`。
3. ✅ **逐槽现取（28／9）**：`nonzero=26` 与装配面（`LineServicesCallbacks.cs:3298-3324`：24 `contextInfo` ＋ 2 `LscbkRedefined`-only = 26）**逐值相符**；`min_nonzero=8/9` 与（9 槽去掉 1 个**不在结构内**的 `InlineFormat`）相符 ⇒ 本侧**逐槽读到的就是托管装配的那批**（§1）。
4. ✅ **真发调 ＋ 两极化（现取）**：`[LSCBF-SELFTEST] mask=0x0f`（值化／真发调／反极拒／闸关拒 = 4/4）；探针 `WPF_PTS_LSCBF_INVOKE=1` ⇒ 桩被**真调**（`stub_calls 0→1`／`invokes=1`／被调返回值**真读** `rc=0x7777`）；缺省（闸关）⇒ `invoke-gate-off(reverse-leg)` **必拒**；未知句柄／越界槽／`SRC_NONE` 空槽 ⇒ 各 `-10000`。
5. ✅ **零回归**：`.so 3118bd1ce7d9604c（改前）→ 0e15268163bbbd71（改后）`；改前腿与改后腿两帧**逐字节相同**（`AE=0`；`k23 10d0b9d54e649c10`／`k24 0bdb2dfd05952bc9`）、症状门逐格同（`alive=yes／app_rc=143／magenta=0／colors 1220/636／ink=480000`）；`PTS_GUARD=PASS legs=2/2`／`PTS_COLORANCHOR=PASS k=24 hits=3` **未回退**。
6. ✅ **门禁四件（现取）**：`nm -D --defined-only` ＝ `exports.txt` ＝ **747**（逐名 `diff` 零差异）；`PTSGAP=PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=0e15268163bbbd71 exports=747`（rc=0）；`DEFREG=PASS declared=225 route_ids=225`（rc=0）；`REPORTID=PASS files=342 ids=2257 declared=225`（rc=0）；`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0`（rc=0）。
7. 🔴 **如实划界（本件的核心判决）**：`PRECOND-NEW-CALLBACK-FACE`（`P1-layout-content-criteria.md:111`）的**形式要件**（须另开一波 ＋ 定其 `ABI`／寿命／快照口径）由本件**满足**；但 `W` 合取（`P1-tail2-dingrecon.md` §3.2）的**语义**要求"面**真被用于取内容**"—— 本侧**不是这批回调的作者**（28 槽全为**入站面**）⇒ **内容侧仍 `7/7` 未解除**（本条只推进"面"这一格，且**只到"可观测／可发调"**）。

---

## §1 回调面**逐槽**现取（28 槽／最小 9 槽；**已解 vs 未解** ＋ 件:行）

> **口径（写死）**：**已解** ＝ 本侧**能逐槽现取真值 ∧ 能发调**（在入参结构内、偏移已证）；**未解** ＝ 该槽**不在两个入参结构内**（本侧**不取、不冒充**）。⚠️ 这与"**内容侧**"是两回事：**内容侧 28 槽全未解**（本侧非作者，`P1-ls-callback-face-recon.md` §5.1）。
> 声明件 `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/MS/internal/TextFormatting/LineServices.cs`（`sha16 8b2bc2167f5c0bd3`）；装配面 `…/LineServicesCallbacks.cs:3298-3324`（`PopulateContextInfo`，`sha16 612c19e675b7ad30`）。偏移一律本侧镜像算得（§2.1 的 `_Static_assert` 钉死）。

| # | 槽 | 声明 `LineServices.cs:行` | 所在结构:偏移 | 最小集 `LS-CB-M1` | **状态（观测/发调侧）** |
|---|---|---|---|---|---|
| 0 | `FetchPap` | `:36` | `LsContextInfo`:`+184` | ✔ | **已解** |
| 1 | `FetchLineProps` | `:42` | `LsContextInfo`:`+192`（**亦** `LscbkRedefined:+16`） | ✔ | **已解** |
| 2 | `FetchRunRedefined` | `:49` | `LscbkRedefined`:`+0` | ✔ | **已解** |
| 3 | `GetRunTextMetrics` | `:64` | `LsContextInfo`:`+272` | ✔ | **已解** |
| 4 | `GetRunCharWidths` | `:72` | `LsContextInfo`:`+248` | ✔ | **已解** |
| 5 | `GetDurMaxExpandRagged` | `:85` | `LsContextInfo`:`+632` | — | **已解** |
| 6 | `DrawTextRun` | `:92` | `LsContextInfo`:`+408` | — | **已解** |
| 7 | `FInterruptShaping` | `:107` | `LsContextInfo`:`+424` | — | **已解** |
| 8 | `GetRunUnderlineInfo` | `:116` | `LsContextInfo`:`+280` | — | **已解** |
| 9 | `GetRunStrikethroughInfo` | `:124` | `LsContextInfo`:`+288` | — | **已解** |
| 10 | `Hyphenate` | `:132` | `LsContextInfo`:`+320` | — | **已解** |
| 11 | `GetNextHyphenOpp` | `:144` | `LsContextInfo`:`+336` | — | **已解** |
| 12 | `GetPrevHyphenOpp` | `:153` | `LsContextInfo`:`+328` | — | **已解** |
| 13 | `GetAutoNumberInfo` | `:162` | `LsContextInfo`:`+160` | — | **已解** |
| 14 | `DrawUnderline` | `:175` | `LsContextInfo`:`+352` | — | **已解** |
| 15 | `DrawStrikethrough` | `:187` | `LsContextInfo`:`+360` | — | **已解** |
| 16 | `GetGlyphsRedefined` | `:199` | `LscbkRedefined`:`+8` | ✔ | **已解** |
| 17 | `GetGlyphPositions` | `:217` | `LsContextInfo`:`+440` | ✔ | **已解** |
| 18 | `DrawGlyphs` | `:235` | `LsContextInfo`:`+448` | — | **已解** |
| 19 | `EnumText` | `:257` | `LsContextInfo`:`+712` | — | **已解** |
| 20 | `EnumTab` | `:281` | `LsContextInfo`:`+720` | ✔ | **已解** |
| 21 | `GetCharCompressionInfoFullMixed` | `:295` | `LsContextInfo`:`+656` | — | **已解** |
| 22 | `GetCharExpansionInfoFullMixed` | `:307` | `LsContextInfo`:`+640` | — | **已解** |
| 23 | `GetGlyphCompressionInfoFullMixed` | `:319` | `LsContextInfo`:`+664` | — | **已解** |
| 24 | `GetGlyphExpansionInfoFullMixed` | `:331` | `LsContextInfo`:`+648` | — | **已解** |
| 25 | `GetObjectHandlerInfo` | `:350` | `LsContextInfo`:`+736` | — | **已解** |
| 26 | `InlineFormat` | `:356` | **不在两结构内**（惰性属性，经 `pfnGetObjectHandlerInfo` 取） | ✔ | 🔴 **未解**（本侧**不取、不冒充**） |
| 27 | `InlineDraw` | `:369` | **不在两结构内**（同上） | — | 🔴 **未解** |

- **计数核对（现取）**：已解 **26**／未解 **2**；最小集 **9** 中已解 **8**（`nonzero` 里 `min_nonzero=8/9`，与真腿读数**逐值相符**）。
- **最小入站面 `LS-CB-M1`（9 槽，`P1-ls-callback-face-recon.md` §5.1）**：`FetchPap`／`FetchLineProps`／`FetchRunRedefined`／`GetRunTextMetrics`／`GetRunCharWidths`／`EnumTab`／`InlineFormat`／`GetGlyphsRedefined`／`GetGlyphPositions`。
- **真腿读出的"非 0 槽数"逐值**：`nonzero=26`（24 `contextInfo` ＋ 2 `redef`-only，**恰**为装配面所装配者）／`redef_nonzero=3`（`LscbkRedefined` 3 槽**全非 0**）。

---

## §2 改动（逐处）

### 2.1 `win32_pts.c`：LS 回调面块

1. **窗口常量**（`WPF_PTS_LSCBF_{REDEF_SIZE=24,INFO_SIZE=744,SLOT_N=28,MIN_N=9,ST_*}`）—— 出处逐条写入注释（`LineServices.cs:803-808`／`:813-963`／`LineServicesCallbacks.cs:3296-3324`）。
2. **入参结构镜像**（`wpf_pts_lsci_mirror`／`wpf_pts_lscbkredef_mirror`）＋ **`_Static_assert` 钉死**：`sizeof(LscbkRedefined)==24`（3 槽 @0/8/16）；`sizeof(LsContextInfo)==760`；26 个回调槽偏移（`+160`…`+736`）与三锚（`+0`／`+20`／`+24`）。**断言即"偏移假设自证"：写死的常量与镜像算得值不符 ⇒ 编译期即红。**
3. **28 槽登记表** `k_pts_lscbf_slots[]`（名／所在结构／偏移／最小集标记）＋ `_Static_assert(条数==28)`。
4. **值化助手** `wpf_pts_lscbf_snapshot()`：`LoCreateContext` 内调；`memcpy` 两窗口；**逐槽取值**（`SRC_NONE` 槽恒 `NULL`）；`redef_nonzero`／`slot_nonzero`／`state`；**布局自证** `layok`（三锚对拍）；一行 `[LSCBF] rx=OK …`。**两个入参任一为 `NULL` ⇒ 响亮 `rx=GAP`、不登记任何"可用"读。**
5. **真发调**：`WpfLinuxWin32_PtsLscbfInvoke(ploc,slot,a0..a3)`（导出） ⇒ 认领 `ploc`（对象身份）→ 槽范围 → 槽非空 → **真调**函数指针（同 `T-A56` 的 `pfnFormatCellFinite` 体例），返回**被调回调的真返回值**；**任一失败 ⇒ `-10000` ＋ 具名 `[LSCBF] invoke=REJECT reason=…`、出参一字不写**。显式闸 `WPF_PTS_LSCBF_INVOKE`（**缺省关**＝硬边界"新增闸缺省关"）。
6. **只读桥接**（导出，供探针/判据现取）：`…PtsLscbf{Rx,RxGap,Invokes,InvokeRejected,SlotCount,MinSlotCount,SlotName,SlotSrc,SlotOff,SlotInMin,SelftestMask,SelfCheck}`／`…PtsLocCbf{State,Nonzero,LayOk,Rx,Invokes,Slot}`／`…PtsLocLiveCount`。
7. **两极化自检** `WpfLinuxWin32_PtsLscbfSelfCheck()`：本侧**自造夹具**（`LsContextInfo`/`LscbkRedefined` 镜像 ＋ **本侧桩**）跑「值化 ∧ 真发调 ∧ 反极拒 ∧ 闸关拒」，返 4-bit `mask`；收尾**真销毁**并**复原全部可观测状态**（泄漏 ⇒ `-1`＝**不算绿**）。**夹具标 `fixture`**（不是托管真面）。
8. **`LoCreateContext` 改动（唯一一行）**：在存下 `context_info`／`lscbk_redef` 之后调 `wpf_pts_lscbf_snapshot()` —— **纯增**、不改任何既有控制流。
9. **`wpf_pts_loc` 结构加字段**（`cbf_redef[24]`／`cbf_info[744]`／`cbf_slot[28]`／`cbf_*` 计数）—— `calloc` 初值 0 ⇒ 无副作用。

### 2.2 登记面 `tools/pts-gap-decl.txt`

DECL 行 `so16 3118bd1ce7d9604c→0e15268163bbbd71`／`exports 727→747`（`tool/dead/artifact/ops/impl` **未动**）＋ 其下**只增**一段 `⚠️ 波 T-A68 重锚` 追注（逐条述面/量/读数/两极化/如实划界）。

### 2.3 复述位现值位（`docs/ROUTES.md` `TASK-0307` 行 ＋ `HANDOFF-NEXT.md` 文件尾）

`ROUTES.md` 加一条 `T-A68` dated 结账（**只增不改**）；`HANDOFF-NEXT.md` 文件尾**只增**机器值契约 `cell=#1／#3` 一行（`inputs_fp b266abcb…→9d051a4c…`）。

### 2.4 为什么**不是**改生成器

本轮**一个字节都没碰** `reapply-patches.py` 及其重产件 —— 本增量全在 native（**零托管改动**）。

---

## §3 成对读数

### 3.1 探针（`dlopen` ＋ `dlsym` ＋ 自检；本席现取）

| 读数 | 缺省（闸关） | `WPF_PTS_LSCBF_INVOKE=1`（闸开） |
|---|---|---|
| `slotCount`／`minSlotCount` | **28／9** | 28／9 |
| 夹具 `LoCreateContext` rc＝0 | ✔（`live=1`） | ✔ |
| 夹具 `state`／`nonzero`／`layok`／`slot26` | **2（VALUE）／1／1／NULL** | 同 |
| `invoke(ploc,0,…)` rc | **`-10000`**（`invoke-gate-off(reverse-leg)`） | **真调 ⇒ `rc=0x7777`**（桩被调 `stub_calls 0→1`） |
| `invokes`／`inv_rej` | 0／**4** | **1**／3 |
| 反极：`null-slot(26)`／`unknown(0xdead)`／`oor(999)` | 各 `-10000` | 各 `-10000` |
| `WpfLinuxWin32_PtsLscbfSelfCheck` | **`mask=0x0f`** | `mask=0x0f` |

**两极化（该红必红）**：① **闸关必拒**（缺省 ⇒ 真发调被拒 ＋ 具名 `reason=invoke-gate-off(reverse-leg)`）；② **反极必拒**（未知句柄／越界槽／`SRC_NONE` 空槽 ⇒ `-10000`，**出参一字不写**）；③ **正极真值**（桩被真调、**返回值被真读**、计数 `0→>0`）。

### 3.2 真腿（`run-pts-pages-legs.sh`；`~/tA68-work/legs/{before,after}/`；两条腿**只差权威 `.so`**）

| 腿 | 权威 `.so` | 证据目录 | `LEGS_RUNNER` |
|---|---|---|---|
| `before` | `3118bd1ce7d9604c`（改前） | `~/tA68-work/legs/before/` | `PASS requested=2 obtained=2 refused=0` |
| `after` | `0e15268163bbbd71`（改后） | `~/tA68-work/legs/after/` | `PASS requested=2 obtained=2 refused=0` |

**症状门（逐腿现取，`leg_*.env`）**：

| 量 | `before` | `after` |
|---|---|---|
| `k24` | `alive=yes app_rc=143 magenta=0 colors=1220 ae=220019 ink=480000` | **同** |
| `k23` | `alive=yes app_rc=143 magenta=0 colors=636 ae=136292 ink=480000` | **同** |
| `failline`（`failfast`／`unrec`） | `0／0` | `0／0` |
| `native_gap`／`managed_unavail` | `0／0` | `0／0` |
| `PTS_GUARD` | `PASS legs=2/2` | **`PASS legs=2/2`** |
| `PTS_COLORANCHOR`（k24） | `PASS hits=3` | **`PASS hits=3`**（`GhostWhite=9794 Beige=910 DarkGreen=44 LightGoldenrodYellow=5830`） |
| `PTS_ENFE` | `PASS total=0` | `PASS total=0` |

**帧面（现取，只读 PNG；`AE`＝逐像素差计数）**：

| 对 | `boot` | `k23` | `k24` |
|---|---|---|---|
| `fr_sha(before)` | `b21eb530afd3c66c` | `10d0b9d54e649c10` | `0bdb2dfd05952bc9` |
| `fr_sha(after)` | `b21eb530afd3c66c` | `10d0b9d54e649c10` | `0bdb2dfd05952bc9` |
| `AE(before,after)` | **0** | **0** | **0** |

⇒ **零回归**（逐字节相同）。

### 3.3 本增量在真腿上的现取读数（**核心**）

`after` 腿 `app_g1.log`（`grep -c '\[LSCBF\]'` ＝ **3**；`rx=GAP` ＝ **0**）：

```
[LSCBF] rx=OK ploc=0x612369be82d0 slots=28 nonzero=26 min_nonzero=8/9 redef_nonzero=3 layok=1 state=VALUE v=LS-CALLBACK-FACE-SNAPSHOTTED
```

- **`rx=OK ×3`**：托管在冷启里**真的把回调面交给本侧 3 次**（`TextFormatterContext.Init()` → `LoCreateContext`）（**"计数 0→>0"**）。
- **`layok=1`**：三锚（`version=4`@+0／`cJustPriorityLim=3`@+20／`wchTab=9`@+32）**对拍全中** ⇒ 本侧镜像偏移与真托管结构一致（**非恒真**：偏移错即 `0`）。
- **`nonzero=26`／`min_nonzero=8/9`／`redef_nonzero=3`**：与装配面（`LineServicesCallbacks.cs:3298-3324`）**逐值相符**。
- `before` 腿等价行 ＝ **0 条**（旧 `.so` 无此观测行）。

> ⚠️ **如实记**：这 3 行是**新增观测行**（本侧打印）；它们**不是**"排版前进"的证据（两腿帧逐字节同）—— 它们证明的是「**面真的来了 ∧ 本侧读得对**」。

---

## §4 门禁（现取；`rc` 一律取自 `>out 2>err; echo $?` 形态）

| 门 | 读数 | rc |
|---|---|---|
| `nm==exports` | `nm -D --defined-only` ＝ **747** ＝ `exports.txt` 行数；**逐名 `diff` 零差异** | 0 |
| `PTSGAP` | `PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=0e15268163bbbd71 exports=747` | 0 |
| `DEFREG` | `PASS declared=225 route_ids=225`；`DECLDRIFT=0 keys=-` | 0 |
| `REPORTID` | `PASS files=343 ids=2257 declared=225`（本件落盘前 `342` ⇒ 落盘后 `343`，`+1` 即本件） | 0 |
| `HANDOFF_MV` | `PASS cells=9 equal=8 manual=1 mismatch=0`（`inputs_fp b266abcb…→9d051a4c…`，已按第 `28` 条契约在 `HANDOFF-NEXT.md` 文件尾**只增**追写） | 0 |
| `PTS-PAGES`（腿产证据） | `PTS_GUARD=PASS legs=2/2`／`PTS_COLORANCHOR=PASS k=24 hits=3`／`PTS_ENFE=PASS total=0` | 0（判据 `--legs` 纯读） |

---

## §5 逐件 `sha16`（现取）

| 件 | 改前 | 改后 |
|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `11a3f6ba49f3f22c`（703908 B） | **`065d204796aec958`**（735288 B） |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so`（**非仓内件**） | `3118bd1ce7d9604c`（503336 B） | **`0e15268163bbbd71`**（504920 B） |
| `src/WpfGfx.Linux.Native/bin/exports.txt`（**非仓内件**） | `d925266b9acd9847`（727 行） | **`5b3e3fbef2e0631d`**（747 行） |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `e19699dbe4c9766b`（586 行） | **`880eb83a4b195133`**（606 行） |
| `docs/ROUTES.md` | `e67ebf7f8e6e3913`（1128 行） | **`6f37d596245666e0`**（1129 行） |
| `build/MilBridge/HANDOFF-NEXT.md` | `72c387ffd286c1ec`（761 行） | **`72c387ffd286c1ec`→含追写行**（762 行） |
| `docs/WAVE66-PREREGISTRATION.md`（**冻证据**） | `bf6b683d94549087` | **未变**（`bf6b683d94549087`） |
| `build/PresentationFramework.Linux/reapply-patches.py`（生成器） | `b6a3a24137a77ddf` | **未变**（零托管改动） |

---

## §6 诚实边界（**防读宽**，逐条）

1. 🔴 **本条只判"面"**：`PRECOND-NEW-CALLBACK-FACE` 的**形式要件**（另开一波 ＋ 定 `ABI`／寿命／快照口径）**满足**；**语义**（"面真被用于取内容"）**不满足** —— 本侧**不是**这 28 槽的作者（全为**入站面**），`W` 合取**仍 `7/7` 未解除**（本条只推进"面"这一格，且只到"**可观测／可发调**"）。
2. 🔴 **"已解"的射程**：§1 的"已解"**只**指「本侧**能逐槽现取真值 ∧ 能发调**」；**不**主张「该槽可**安全**调用」（真实回调需 LS 引擎语义；乱调必撞 `Invariant.FailFast`）⇒ 真发调走**缺省关**的显式闸，**产品路径不主动发调任何真实回调**。
3. 🔴 **`nonzero=26` 不是"内容层有源"**：它**只**证明"托管装配了 26 个回调指针且本侧按偏移读到了"；**内容**（真度量／字符源／行断）仍无源（`PRECOND-NO-TEXT-SOURCE`／`PRECOND-NO-LINE-BREAKER`）。
4. 🔴 **`InlineFormat`／`InlineDraw` 两槽未解**：它们**不在** `LsContextInfo`／`LscbkRedefined` 两入参结构内（惰性属性，经 `pfnGetObjectHandlerInfo` 取）⇒ 本侧 `SRC_NONE`、恒 `NULL`、**不冒充**（`P3`／`P8`）。
5. 🔴 **布局自证的射程**：`layok` 只对拍**三处托管真置值字段**（`version`／`cJustPriorityLim`／`wchTab`）＋ 由 26 槽非零**间接**佐证指针区；它**不**逐字段证明每个偏移（26 个槽的同形「8 B 指针、连续排布」使单槽偏移错会**同时**错位 ⇒ 三锚 ＋ 26 值已**强**约束，但**非逐槽独立实测**）。
6. 🔴 **真发调的证据来源**：`invokes` 的 `0→>0` 由**自检夹具的本侧桩**产生（具名 `fixture`）；**真实回调未被调**（安全）。这是"**机制**"证据，**不**是"内容"证据。
7. 🔴 **新增观测行不改变行为**：`[LSCBF] rx=OK` 每上下文一行、`stderr`；两腿帧逐字节同（§3.2）⇒ **零像素位移**。
8. **`bin/*` 非仓内件**：`src/WpfGfx.Linux.Native/bin/` 在 `.gitignore` ⇒ 由 `build-shim.sh --symbols` 每次重产；`nm==exports` 是**构建不变量**。
9. **未跑整趟 `verify-all`**（照派单）；本节所有"不得读成绿"的口径照在册红榜 `P1–P10`。

---

## §7 遗留（下一增量具名靶）

- **`InlineFormat`／`InlineDraw` 两槽**：不在两入参结构内 ⇒ 若要"取"，须经 `pfnGetObjectHandlerInfo` 的**处理器信息**（`FSCBKOBJ`-类）——**本侧无 native 对象处理器**（`T-A62` 在册）⇒ 须另立前置，**不冒充**。
- **内容侧**：`W` 的其余 6 项（`C2`／`C4`／`PRECOND-NO-TEXT-SOURCE`／`PRECOND-NO-LINE-BREAKER`／`PRECOND-NO-TEXT-PARA-IN-CHAIN`／`PRECOND-LS-SESSION-DRIVER`）**未解除**；本件**不**授权任何判据放宽。
- **可选的下一步**：把"逐槽**独立**偏移实测"补齐（每条槽一次真值对拍）——今天只有三锚 ＋ 26 值约束。
- **`C2` 的 `ploc` 一半**：本侧 `LoCreateContext` 已真实现并导出 ⇒ "LS 会话进链"这半**本侧已有**（承 `T-A67` §3.3-1）；但"托管是否真驱动 `Lo*` 引擎"仍 `NOINFO`（本件的 `rx` 只证"`LoCreateContext` 被调"，**不**证"LS 引擎在跑"）。

---

`P1-TAIL2-LSCBF 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ a5edce64baf80d7e（末行＝本行）`

# `P1-tail2` · `T-A62` · `Lo*`/`Nl*` 族缺口首批（**可诚实实现子集 3 条 ＋ 同族唯一 stub 升格 1 条**）—— 实现报告（**判决：≥8 条真实现的前提在本侧**不成立**（如实划界）：只做**可诚实实现者** `LoSetTabs`／`LoCreateParaBreakingSession`／`LoDisposeParaBreakingSession`（＋把同族唯一 stub `LoDisposePenaltyModule` 升为真实现）⇒ 在册数 `tool 62→59／ops 50→47／impl 51→47／stubs 1→0／exports 701→718` 逐字段现算对账 `PTSGAP=PASS`；`nm==exports` 零差异；两极化 `mask=0x0f`（反腿副本 `mask=0x07`）；`PTS_GUARD=PASS`／`PTS_COLORANCHOR=PASS hits=3` **未回退**；两腿帧 `AE=0`；`Nl*` 6 条按在册语义**有意降级**保持**未导出**（`NL_INTENT=PASS`）**）

- **读时**：`2026-10-01T18:1x–18:2x+0800`（本席现取，各条另注）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`（**未 `git add/commit/push`**）。
- **改前件备份（仓外 `~/tA62-work/bak/`，`cp -p`，取在**任何写之前**）**：`win32_pts.c`（`002f9e04264d123c`）／`bin/exports.txt`（`7853a5c88214957a`）／`bin/libwpfwin32.so`（`2852242a1c946d1f`）／`tools/pts-gap-decl.txt`（`2aeb72ccd9bf9dc2`）。
- **写域（逐件）**：`src/WpfGfx.Linux.Native/src/win32_pts.c`（**新增一段：3 条 `Lo*` 真实现 ＋ `LoDisposePenaltyModule` 升格 ＋ 4 条两极化自检 ＋ 只读桥接 ＋ struct 加制表位位**）／`src/WpfGfx.Linux.Native/bin/exports.txt`（**构建重产**，非手改）／`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（DECL 行五数 ＋ `so16`/`exports` ＋ dated `T-A62` 重锚追注）／**复述位现值位**（`docs/ROUTES.md` 三处／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 两处 ＋ `T-A52..A61` 归因段末追 `T-A62`／`build/MilBridge/HANDOFF-NEXT.md`：`§3` 现值位 ＋ 文件尾机器值契约 `cell=#1／#3` 追写／`src/WpfGfx.Linux.Native/src/win32_classification.c` 注释现值位）／**新建载体** 本件。
- **未改**（如实体例）：`build/PresentationFramework.Linux/reapply-patches.py`（生成器一字未动）；`docs/WAVE66-PREREGISTRATION.md`（**冻证据**）`w66pre16=bf6b683d94549087` 未动。
- **黑名单遵守**：未动 `build/MilBridge/tools/**`（**只读跑**判据件）／`verify-all.sh`／`build/close-wave.sh`／`build/shims/**`／`build/PresentationFramework.Linux/**`／`upstream/**`（只读）；**未跑**整趟 `verify-all`；未改相位位；未 `git add/commit/push`。
- **重活**：**3 趟 native 构建**（主链 2 ＋ 反腿副本 1）＋ **2 趟跑器**（共 **4 条腿**），全走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- <cmd>`（逐趟 `HEAVYSLOT=RELEASED rc=0`）；进程只按 PID；显示位只用空闲 `:231`（逐趟 `DISPLAY_PICK :231`／`DEVICE_REAP state=clean`）；禁 `sleep` 轮询；写前 `cp -p`；`temp+rename`；模式守恒。
- **口径**：一切读数**本席现取**（`sha256sum`／`nm -D --defined-only`／`diff`／`grep -c`／dlopen 探针 `gcc` 编译的 `~/tA62-work/probe`／只读 `python3`＋`PIL` 自算 `AE`／`bash build/MilBridge/tools/{pts-gap-count-check,pts-pages-guard,defect-registry-check,report-id-domain-check,handoff-machine-values-check,nl-intent-check}.sh`）。

---

## §0 结论速览（自包含）

1. 🔴 **任务前提「≥8 条真实现」在本侧**不成立**（如实划界，**不**假成功）**：`Lo*`/`Nl*` 族共 21 条缺口（`Lo*` 15 ＋ `Nl*` 6），其中**只有 3 条**满足诚实准入（**无几何出参 ∧ 不依赖行/字符内容**）：`LoSetTabs`／`LoCreateParaBreakingSession`／`LoDisposeParaBreakingSession`；另把同族**唯一**缺口 stub `LoDisposePenaltyModule` **升为真实现**。其余 **11 `Lo*`** 因**出参含真几何而无测量源**、**6 `Nl*`** 因**在册语义＝有意降级**，**一律不冒充**（保持现状）。**按硬边界「诚实拒绝优于假成功」，本趟只做可诚实实现者。**
2. ✅ **3 条真实现（非恒 `-10000`）＋ `LoDisposePenaltyModule` 升格**：语义**逐字**照 `LineServices.cs`（见 §1）。**两极化（dlopen 探针现取）**：改前 3 名 `present=0/3`（缺符号）；改后 `present=3/3` 且 `[LSBATCH2-SELFTEST] mask=0x0f`＝4/4「正极真值 ∧ 反极必拒」；**反腿副本**（去掉 `LoDisposePenaltyModule` 的对象身份认领）⇒ `mask=0x07`（**该位必红**）。
3. ✅ **诚实准入铁律**：只收**自持对象**（上下文／段断行会话／罚分模块）的**生命周期与状态搬运**；**凡出参含真几何、或需行内容/字形者一律不冒充**——`LoCreateLine`（出参 `LsLInfo` 22 字段全度量 ＋ `LsLineWidths` 7 字段 ＋ `maxDepth`）／`LoCreateBreaks`／`LoEnumLine`／`LoQueryLineCpPpoint`／`LoQueryLinePointPcp`／`LoDisplayLine`／`LoAcquireBreakRecord`／`LoDisposeLine`／`LoDisposeBreakRecord`／`LoCloneBreakRecord`／`LoRelievePenaltyResource`／`LocbkGetObjectHandlerInfo` 共 **11 条**（保持缺口；其根对象「行／断行记录」**无诚实创造者** ⇒ 生命周期对端亦无源）。
4. ✅ **在册数逐字段现算对账**：`PTSGAP=PASS tool=59 dead=11 artifact=1 ops=47 impl=47 so16=327dcce237e03e1f exports=718`（`rc=0`）；`dead/artifact/w66pre16` 未动；`nm -D --defined-only` ＝ `exports.txt` ＝ **718**（逐名 `diff` **零差异**）。**3 条（缺口下降）＋ 1 条（stub 升格）＝ 4 条与计数逐字段一致**。
5. ✅ **门禁未回退**：`PTS_GUARD=PASS legs=2/2`／`PTS_COLORANCHOR=PASS k=24 hits=3`（两腿同）／`PTS_ENFE=PASS total=0`；`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0`／`DEFREG=PASS`／`REPORTID=PASS`／**`NL_INTENT_RESULT=PASS capability=0 declared=yes anchors=3/3`（`Nl*` 6 名**一个都没导出**）**。
6. ✅ **症状门 ＋ 帧面成对（只差 `.so`）**：腿 `before`（旧 `.so 2852242a1c946d1f`）与 `after`（新 `.so 327dcce237e03e1f`）三帧**逐字节相同**（`AE=0`：`boot b21eb530afd3c66c`／`k23 10d0b9d54e649c10`／`k24 0bdb2dfd05952bc9`）、症状门逐格同（`alive=yes／app_rc=143／magenta=0／ink=480000／colors 386/636/1220／ns=…FlowDocumentDemo｜…RichTextBoxDemo`／`[HC-UNHANDLED]=0`／`entry point named=0`／`[LSBATCH2]` **两腿命中 0**）。
7. 🔴 **计数下降 ≠ 能力前进**（件头第 ① 条同口径）：4 条入口在**现产品路径未被调用**（两腿 `[LSBATCH2]` 命中 **0**、三帧 `AE=0`；且本侧 `Lo*` 面**已被托管 `pfnFormatLine` 链取代**——`build/MilBridge/P1-tail2-hostline-recon.md` §3 判 native LS「**不必要** ∧ 代价极高」）⇒ 本增量把**缺符号**变成**有符号的真实现**，**页仍未被全绘**。

---

## §0.5 方案（本趟**单方案**；未做多方案试探，上限 3 未用满，如实记）

| 方案 | 形态 | 现取读数 | 判决 |
|---|---|---|---|
| **1** | 只收**自持对象**的**生命周期/状态搬运**（无几何出参、不依赖行内容）＝ 3 条；并把同族唯一 stub 升格；每条先认领后动作，反极必拒 | `mask=0x0f`（正极＋反极 4/4）；反腿副本 `mask=0x07` | ✅ **达** |

> 「出参含真几何或需行内容者」被**显式排除**（不是"没来得及"）：本侧**不是** LineServices **排版引擎**的作者（`PRECOND-NO-TEXT-SOURCE`：本侧无字符源；`PRECOND-LS-SESSION-DRIVER`：native 须成"被托管调用、再回调托管"的重入方）⇒ 凡"要交出字盒/度量/字形"的入口，本侧**无源** ⇒ 保持缺口、不冒充。**故无「方案 2／3」。**

---

## §1 逐条（件:行语义出处 ＋ 实现前后成对读数）

> 「实现前」＝ dlopen 探针 `present=0`（缺符号 ⇒ 托管一旦到达即 `EntryPointNotFoundException`）；「实现后」＝ `present=1` ＋ 自检正极真值（真返回值可现取）＋ 反极必拒（`-10000` ＋ 具名 `[LSBATCH2]`）。

| # | 入口（声明 件:行 → 调用点 件:行） | 诚实语义（逐字） | 实现前 | 实现后（正极 ⇒ 真值／反极 ⇒ 拒） |
|---|---|---|---|---|
| ① | `LoSetTabs` `LineServices.cs:1478-1484` → `TextFormatterContext.cs:374`（`SetTabs`）／`TextParagraphCache.cs:50` | 把 `durIncrementalTab` ＋ `LsTbd[tabCount]`（每 12 B：`int lskt`+0／`int ur`+4／`u16 leader`+8／`u16 chartab`+10）**真落盘**到**该 `ploc` 的上下文对象**上（逐字段按真实类型读，可独立读取；本侧一个字节都不写回入参） | `present=0` | 正极：`rc=0 v=TABS-STORED` ∧ `tab_inc=720 tab_count=2` 且逐条 `lskt/ur/leader/chartab` 读回相符；反极：未知上下文／`tabCount>32`／`tabCount>0 ∧ pTabs=NULL` ⇒ `rc=-10000 reason=unknown-context/tab-count-out-of-range/null-tabs` |
| ② | `LoCreateParaBreakingSession` `LineServices.cs:1533-1542` → `TextParagraphCache.cs:54` | 按对象身份认领 `ploc` 后**真造**本侧自有「段断行会话」对象（句柄＝对象本身，绑定所属上下文）；`fParagraphJustified` 取**保守缺省 0**（本侧无宿主 `FetchPap` 对齐来源，具名 `NOINFO-PARABRK-JUSTIFY`） | `present=0` | 正极：`rc=0` ∧ `sess≠NULL` ∧ `justified=0` ∧ 对象绑定 `ctx`／`cpFirst=10`／`maxWidth=400`；反极：未知上下文／空出参（两处各一）⇒ `rc=-10000 reason=unknown-context/null-out-session/null-out-justified` |
| ③ | `LoDisposeParaBreakingSession` `LineServices.cs:1544-1549` → `TextParagraphCache.cs:150` | **真销毁**该会话对象（登记表移除；重复／未知／`NULL` 一律拒） | `present=0` | 正极：`rc=0` ∧ `wpf_pts_lsps_find(sess)==NULL`（不可再认领）；反极：`NULL`／`0xDEAD`／重复 ⇒ `rc=-10000 reason=null-session/unknown-session` |
| ④ | `LoDisposePenaltyModule`（**升格**）`LineServices.cs:1575-1578` → `TextPenaltyModule.cs:59` | 按**模块句柄身份**（＝某个在册上下文对象的 `penalty_module_handle` 字段地址）认领后**真失效**该字段（于是 `LoGetPenaltyModuleInternalHandle` 再拿它必被拒）；`NULL`／未知／重复一律拒 | 已导出但恒 `-10000`（**诚实 stub**） | 正极：`LoAcquirePenaltyModule` 后 `LoDisposePenaltyModule(mod)=0` ∧ 再 `LoGetPenaltyModuleInternalHandle(mod,&q)` ⇒ `rc=-10000` 且 `q==NULL`；反极：`NULL`／`0xDEAD`／重复 ⇒ `rc=-10000 reason=null-module/unknown-module` |

> 语义出处铁律：每个入口的**行为形状**由 `LineServices.cs` 的 `DllImport` 声明（行号见表）＋ 其**唯一调用点**（行号见表）共同界定；本侧不发明协议。

---

## §2 改动（逐处）

### 2.1 `win32_pts.c`：3 条真实现 ＋ 1 条升格 ＋ 自检 ＋ 只读桥接
- **struct 加字段**：`wpf_pts_loc` 增 `tab_inc`／`tab_count`／`tab_sets` ＋ 四张 `tab_*[WPF_PTS_LS_TAB_MAX]`（`WPF_PTS_LS_TAB_MAX=32`）；`calloc` 初值 0 ⇒ 无副作用。
- **新对象**：`wpf_pts_lsps`（「段断行会话」，`WPF_PTS_LSPS_MAGIC "PTSS"`／有界表 `WPF_PTS_LSPS_MAX=64`）＋ `wpf_pts_lsps_find`（**只按指针身份**，不 deref）。
- **3 条新导出 ＋ 1 条升格**：置于 `WpfLinuxWin32_PtsPenaltyInternalGets` 之后，共用一个具名失败面助手 `wpf_pts_b2_gap()`（`[LSBATCH2] rc=-10000 reason=… entry=… p=… out=UNWRITTEN bytes=0`）与成功面 `[LSBATCH2] rc=0 …`。
- **逐条两极化自检** `WpfLinuxWin32_PtsLsBatch2SelfCheck()`：自造 1 上下文夹具，跑「正极真值 ∧ 反极必拒」，返回 4-bit `mask`；**收尾真销毁全部夹具对象并断言活数回 base**（泄漏 ⇒ `-1`，**不算绿**）；自检只改自己的对象与自己的计数。
- **只读桥接**（导出，供探针/判据现取）：`…PtsLsBatch2{SelftestMask,Ok,Gap}`／`…PtsLsSession{Live,Creates,Destroys,Rejected}`／`…PtsLsTabs{Sets,Rejected}`／`…PtsPenalty{Disposed,DisposeRejected}`／`…PtsLocTabInt`／`…PtsLocTabEntry`。
- **反腿开关**：**无**（反腿以**副本 `sed`** 构造，主链产物**一个字节不带**反腿分支 —— 见 §3.3）。

### 2.2 登记面 `tools/pts-gap-decl.txt`
DECL 行 `tool/ops/impl/so16/exports` 五格更新（`59/47/47/327dcce237e03e1f/718`；`stubs 1→0`）；其下**只增**一段 `⚠️ 波 T-A62 重锚` 追注：逐条述 3 条 ＋ 升格、诚实准入铁律、计数逐字段、`so16` 换代、判据成对读数、两极化（探针 mask），并**如实**记「≥8 条真实现不可诚实满足」。

### 2.3 复述位现值位（只改数）
`docs/ROUTES.md`（`:262`／`:402`／`:549`）／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（两处现值位 ＋ 逐增量归因段末追 `T-A62`）／`src/WpfGfx.Linux.Native/src/win32_classification.c` 的现值位 `50/51/62` ⇒ **`47/47/59`**。`build/MilBridge/HANDOFF-NEXT.md`：`§3` 现值位随动 ＋ **文件尾只增**两行机器值契约 `cell=#1／#3`（`inputs_fp` 因写域件 `win32_pts.c`／`pts-gap-decl.txt`／`win32_classification.c` **在覆盖面内** ⇒ 必然位移 `bd2e70b2…→a5984a2c…`）。
- **历史行原文保留** —— 它们**自引旧代锚 ＋ dated 措辞**，判据件按裁定九**不参与现值判定**（现取 `PTSGAP_HISTORICAL=n=11`）。

### 2.4 为什么**不是**改生成器
本轮**一个字节都没碰** `reapply-patches.py` 及其重产件 —— 本增量全在 native（**零托管改动**）。

---

## §3 成对读数（**同装置 `:231`**；证据 `~/tA62-work/`）

### 3.1 探针（dlopen ＋ dlsym ＋ 自检；`present` 与 `mask` 本席现取）

| 读数 | **改前**（旧 `.so 2852242a1c946d1f`） | **改后**（新 `.so 327dcce237e03e1f`） |
|---|---|---|
| 3 名 `present` | **0/3**（缺符号） | **3/3** |
| `WpfLinuxWin32_PtsLsBatch2SelfCheck` 符号 | 0 | 1 |
| `PROBE SELFTEST_MASK` | （无符号） | **`0x0f`**（settabs／parabrk_create／parabrk_dispose／pen_dispose ＝ 1） |
| 判词 | — | `[LSBATCH2-SELFTEST] mask=0x0f … legs=4/4(POS+REJECT)` |

**正极真值（`mask` 的承重读数，逐条可现取）**：`LoSetTabs` ⇒ `tab_inc=720 tab_count=2`、`tab[0]=(lskt=3,ur=1440,leader=0x2E,chartab=0x09)`；`LoCreateParaBreakingSession` ⇒ `session≠NULL, justified=0, ctx 绑定`；`LoDisposeParaBreakingSession` ⇒ 销毁后不可再认领；`LoDisposePenaltyModule` ⇒ 失效后 `LoGetPenaltyModuleInternalHandle` 必拒且清出参。

### 3.2 反极性（该红必红）
每条入口的**反极腿**在自检内**同一谓词**判（§1 表"反极"列）：`NULL`／外来值（`0xDEAD`）／已失效值／重复 一律 `rc=-10000` ＋ 具名 `[LSBATCH2]`，出参**一字不写**（`out=UNWRITTEN bytes=0`）。

### 3.3 反腿副本（**证明自检真有牙**）
以 `python3` 造**仓外副本** `~/tA62-work/badrepl/`：仅去掉 `LoDisposePenaltyModule` 的**对象身份认领**（对任意非 `NULL` 句柄也返 0）⇒ 同一探针现取 **`mask=0x07`（`pen_dispose=0`）** ⇒ 该位**必红**、自检**不是恒真**。**主链产物不含任何反腿分支**（一个字节不受影响）。

### 3.4 腿（`run-pts-pages-legs.sh`；两条腿**只差权威 `.so`**，其余全同）

| 腿 | 权威 `.so` | 证据目录 | `LEGS_RUNNER` |
|---|---|---|---|
| `before` | `2852242a1c946d1f`（改前） | `~/tA62-work/legs/before/` | `PASS requested=2 obtained=2 refused=0` |
| `after` | `327dcce237e03e1f`（改后） | `~/tA62-work/legs/after/` | `PASS requested=2 obtained=2 refused=0` |

**症状门（逐腿现取）**：

| 量 | `before` | `after` |
|---|---|---|
| `k24` | `alive=yes app_rc=143 magenta=0 colors=1220 ns=…FlowDocumentDemo ae=220019 ink=480000` | **同** |
| `k23` | `alive=yes app_rc=143 magenta=0 colors=636 ns=…RichTextBoxDemo ae=136292 ink=480000` | **同** |
| `boot` | `colors=386 magenta=0 ink=480000` | **同** |
| `[HC-UNHANDLED]` / `entry point named` / `[LSBATCH2]` | `0` / `0` / `0` | `0` / `0` / **0**（4 条**未被调用**） |
| `PTS_COLORANCHOR` | `PASS k=24 hits=3`（`GhostWhite=9794 Beige=910 DarkGreen=44 LightGoldenrodYellow=5830`） | **PASS hits=3**（同值） |
| `PTS_GUARD` | `PASS legs=2/2` | **PASS legs=2/2** |
| `PTS_ENFE` | `PASS total=0` | **PASS total=0** |

**帧面成对（本席自算，只读 PNG）**：`AE(before,boot)=0`／`AE(before,k23)=0`／`AE(before,k24)=0`（`fr_sha` 逐格相等：`boot b21eb530afd3c66c`／`k23=10d0b9d54e649c10`／`k24=0bdb2dfd05952bc9`）⇒ **4 条入口在现产品路径未被调用 ⇒ 逐字节零位移**（这正是本节要证的事，不是"没测"）。

### 3.5 门禁六件（现取）

| 门 | 读数 | rc |
|---|---|---|
| `nm==exports` | `nm -D --defined-only` ＝ **718** ＝ `exports.txt` 行数；**逐名 `diff` 零差异** | 0 |
| `PTSGAP` | `PASS tool=59 dead=11 artifact=1 ops=47 impl=47 so16=327dcce237e03e1f exports=718` | 0 |
| `HANDOFF_MV` | `PASS cells=9 equal=8 manual=1 mismatch=0` | 0 |
| `DEFREG` | `PASS declared=225 route_ids=225`（`DECLDRIFT=1 keys=KD`：本趟改 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 现值位 ⇒ 该 route 件离开声明锚；`defect-registry-declared.tsv` 在**黑名单**内 ⇒ **未重发**，如实记） | 0 |
| `REPORTID` | `PASS files=338 ids=2246 declared=225`（本件落盘前 `338` ⇒ 落盘后 `339`，`+1` 即本件） | 0 |
| `NL_INTENT` | `PASS capability=0 declared=yes anchors=3/3`（`Nl*` 6 名**一个都没导出**） | 0 |

---

## §4 逐件 `sha16`（现取）

| 件 | 改前 | 改后 |
|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `002f9e04264d123c` | **`2b8142ced5b68b76`** |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so`（**非仓内件**） | `2852242a1c946d1f`（480488 B） | **`327dcce237e03e1f`**（490072 B） |
| `src/WpfGfx.Linux.Native/bin/exports.txt`（**非仓内件**） | `7853a5c88214957a`（701 行） | **`20b6d9aa3125bbc4`**（718 行） |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `2aeb72ccd9bf9dc2` | **`5965cc3e9ed89498`** |
| `docs/ROUTES.md` | — | **`e67ebf7f8e6e3913`** |
| `README.md` | — | **`edfb3b358c516c0a`** |
| `docs/unimplemented.md` | — | **`9056aaa690aed27a`** |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | — | **`883231e1ba36dea6`** |
| `build/MilBridge/HANDOFF-NEXT.md` | — | **`d03e4c2b7a3dc6e1`** |
| `src/WpfGfx.Linux.Native/src/win32_classification.c` | — | **`252fa66042600f78`** |
| `docs/WAVE66-PREREGISTRATION.md`（**冻证据**） | `bf6b683d94549087` | **未变** |
| `build/PresentationFramework.Linux/reapply-patches.py`（生成器） | — | **未变** |

---

## §5 诚实边界（防读宽，逐条）

1. **「3 条真实现」只主张「符号在册 ＋ 按在册语义真动作 ＋ 反极必拒」，不主张「排版能力前进」**：4 条在现产品路径**未被调用**（§3.4，`[LSBATCH2]` 两腿命中 0、三帧 `AE=0`）⇒ 页仍**未全绘**。**计数下降 ≠ 能力前进**（件头第 ① 条）。
2. 🔴 **任务前提「≥8 条真实现」不成立（本趟的核心判决）**：`Lo*`/`Nl*` 族 21 条缺口里，**18 条不可诚实实现**（详见下表）⇒ 本趟按硬边界**只做 3 条 ＋ 升格 1 条**，其余**保持现状并如实划界**（**不**假成功）。
3. **几何一律不冒充**：`LoCreateLine` 的出参 `LsLInfo`（22 字段：`dvpAscent`／`dvrAscent`／… 全度量）／`LsLineWidths`（7 字段：`upStartMarker`…`upMinLimLine`）／`maxDepth`，本侧**无测量源**（`PRECOND-NO-TEXT-SOURCE`）⇒ 返回 0 会造「静默半通」（本仓最忌讳形态）⇒ **只能拒绝**，故**不作真实现**；其生命周期对端（`LoDisposeLine`／`LoAcquireBreakRecord`／`LoCloneBreakRecord`／`LoDisposeBreakRecord`／`LoRelievePenaltyResource`）因此**无根对象**。
4. **保守缺省已具名**：`LoCreateParaBreakingSession` 的 `fParagraphJustified` 本侧无宿主 `FetchPap` 对齐来源 ⇒ 取**保守缺省 0**（＝不按两端对齐罚分，与托管 `_penalizedAsJustified` 字段缺省同值）并具名 `NOINFO-PARABRK-JUSTIFY`（**不**冒充"排版判定结果"）。
5. **被排除的入口是「如实划界」不是「遗漏」**（逐条给"不可诚实实现"的机器理由）：

   | 入口 | 声明的出参/语义 | 不可诚实实现的理由（现取） |
   |---|---|---|
   | `LoCreateLine` | `out LsLInfo`／`out pploline`／`out maxDepth`／`out LsLineWidths` | 出参含**真几何**（度量/宽度），本侧无字源/度量源 |
   | `LoCreateBreaks` | `ref LsBreaks`（断点集＋逐断点 `LsLInfo`）／`out bestFitIndex` | 需**行断器**（断点＝排版产物） |
   | `LoEnumLine`／`LoQueryLineCpPpoint`／`LoQueryLinePointPcp`／`LoDisplayLine` | 行盒/字盒/命中查询/显示 | 需**行内容＋字形**（`ploline` 本侧不存在） |
   | `LoAcquireBreakRecord`／`LoDisposeLine`／`LoRelievePenaltyResource` | 行／断行记录生命周期（无几何出参） | 在册语义**以内联对象为对象**（对自有对象语义不成立 ⇒ 如实划界） |
   | `LoCloneBreakRecord`／`LoDisposeBreakRecord` | 断行记录生命周期 | 同上（`pBreakRec` 对自有对象不存在） |
   | `LocbkGetObjectHandlerInfo` | native 对象处理器信息（`objectInfo`） | 本侧**无 native 对象处理器**（`TextStore.ObjectId.MaxNative`＝1） |
   | `NlCreateHyphenator`／`NlDestroyHyphenator`／`NlHyphenate`／`NlGetClassObject`／`NlLoad`／`NlUnload` | **在册语义＝有意降级** | `build/MilBridge/tools/nl-intent-check.sh` 段①：6 名**一个都不许导出**（`rc=0` 时 `EXPORT_STATE=CAPABILITY_ZERO`）；`D-G76`：`NlCreateHyphenator` 返 `IntPtr`，返 `-10000`＝**假句柄** ⇒ 守卫当场失效 |

6. **`bin/*` 非仓内件**：`src/WpfGfx.Linux.Native/bin/` 在 `.gitignore` ⇒ 该件由 `build-shim.sh --symbols` **每次重产**；`nm==exports` 是**构建不变量**（不是"我们手工对齐了一份表"）。
7. **新引入一条 `-Wunused-function` 警告（如实记，非门禁）**：本趟把**最后一个** `return wpf_pts_gap("…")` stub（`LoDisposePenaltyModule`）升格 ⇒ `wpf_pts_gap()` 成为**未被调用**的静态函数（GCC `-Wall` 报 1 行 `defined but not used`）。该形态**在现盘本已存在同类**（`wpf_pts_fsp_pl_is_sentinel` 同警告）；`stubs` 因此归 0（`impl = ops + stubs` 恒式仍成立）。**未删** `wpf_pts_gap` 本体（保留给后续新 stub）。
8. **自检只改"自己的对象与自己的计数"**：`WpfLinuxWin32_PtsLsBatch2SelfCheck()` 收尾真销毁全部夹具对象并**断言活数回 base**（否则返 `-1` ＝**不算绿**）；它**不**改任何产品状态／台账／计数。
9. **反腿以副本构造**（`~/tA62-work/badrepl/`，仓外）：主链源码**不含**反腿宏/分支 ⇒ 反向不引入产品面分支。

---

## §6 遗留（下一增量具名靶）

- **`Lo*` 族**：其余 11 条**不可诚实实现**（无 LS 引擎/字源）⇒ 若要真做，须先落**具名前置**：`PRECOND-MEASURED-LS-CALLBACK-OFFSETS`（LS 回调槽实测偏移，须写域外同伴）＋ `PRECOND-LS-SESSION-DRIVER`（native 成重入方）＋ `PRECOND-NO-TEXT-SOURCE`（字源）—— **即"native 重实现 LS 引擎"，本仓现取判「不必要 ∧ 极高代价」**。
- **`Nl*` 族**：在册语义＝**有意降级**；若要翻，须**同趟**重测行为 ＋ 更新在册声明 ＋ 处置 `nl-intent-check.sh` 段①（本任务黑名单内，**不可改**）。
- **`Fs*` 族**：`T-A61` 已做首批 8 条；余量见 `build/MilBridge/P1-tail2-gapbatch1-impl-report.md` §6。
- **`declared.tsv` 的收波随动**：由不在本任务黑名单内的收波步骤完成。

---

`P1-TAIL2-GAPBATCH2 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 49e56dfdca415faa（末行＝本行）`

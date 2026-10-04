# `P1-tail2` · `T-A66` · 甲类 5 条（`T-A65` §3 清单第三批）—— 实现报告（**判决：5 条可诚实实现者已真实现并导出；两极化（正极真值 ∧ 反极必拒）现取 `mask=0x1f`、反腿副本 `mask=0x1e`；在册数 `tool 59→54／ops 47→42／impl 47→42／exports 718→727` 逐字段现算对账 `PTSGAP=PASS`；`nm==exports` 零差异；`PTS_GUARD=PASS`／`PTS_COLORANCHOR=PASS hits=3` **未回退**；两腿帧 `AE=0`**）

- **读时**：`2026-10-01T20:0x–20:2x+0800`（本席现取，各条另注）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，`HEAD=276dac0`（分支 `feat-Linux`；**未 `git add/commit/push`**）。
- **改前件备份（仓外 `~/tA66-work/bak/`，`cp -p`，取在**任何写之前**）**：`win32_pts.c`（`c80a03e9633641a7`）／`win32_internal.h`（`adfa3fcd8b926d6a`）／`bin/exports.txt`（`20b6d9aa3125bbc4`）／`bin/libwpfwin32.so`（`969536ee1549ef39`）／`tools/pts-gap-decl.txt`（`d78e5b0c65dc1e89`）（另备 `win32_core.c`／`win32_misc.c` 作**未改**对照）。
- **写域（逐件）**：`src/WpfGfx.Linux.Native/src/win32_pts.c`（**新增一段：5 条真实现 ＋ 逐条两极化自检 ＋ 4 个只读桥接 ＋ `struct wpf_pts_fsp` 增 `br_destroyed` 位**）／`src/WpfGfx.Linux.Native/src/win32_internal.h`（`struct wpf_window` **增 `scroll_pos[2]`**：`SetScrollPosWrapper` 的位置位）／`src/WpfGfx.Linux.Native/bin/exports.txt`（**构建重产**，非手改）／`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（DECL 行五数 ＋ `so16` ＋ `exports` ＋ dated `T-A66` 重锚追注）／**复述位现值位**（`docs/ROUTES.md` 三处／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 两处／`build/MilBridge/HANDOFF-NEXT.md`：`§3` 现值位 ＋ 文件尾机器值契约 `cell=#1／#3` 追写／`src/WpfGfx.Linux.Native/src/win32_classification.c` 注释现值位）／**新建载体** 本件。
- **未改**（如实体例）：`build/PresentationFramework.Linux/reapply-patches.py`（生成器一字未动）；`docs/WAVE66-PREREGISTRATION.md`（**冻证据**）`w66pre16=bf6b683d94549087` 未动；`win32_core.c`／`win32_misc.c`（**本批未碰**，见 §2.4）。
- **黑名单遵守**：未动 `build/MilBridge/tools/**`（**只读跑**判据件）／`verify-all.sh`／`build/close-wave.sh`／`build/shims/**`／`build/PresentationFramework.Linux/**`／`upstream/**`（只读）；**未跑**整趟 `verify-all`；未改相位位；未 `git add/commit/push`。
- **重活**：**3 趟 native 构建**（主链 2 ＋ 反腿副本 1）＋ **3 趟跑器**（`before` ×1、`after` ×2 —— 第 2 次 `after` 因**主链 `.so` 在自检后同趟微调了失败面留痕文本**而重取，详见 §3.4）全走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- <cmd>`（逐趟 `HEAVYSLOT=RELEASED rc=0`）；进程只按 PID；显示位只用空闲 `:23x`（逐趟 `DISPLAY_PICK :231`／`DEVICE_REAP state=clean`）；禁 `sleep` 轮询；写前 `cp -p`；`temp+rename`；模式守恒。
- **口径**：一切读数**本席现取**（`sha256sum`／`nm -D --defined-only`／`diff`／`grep -c`／dlopen 探针 `gcc` 编译的 `~/tA66-work/probe`／只读 `python3`＋`PIL` 自算 `AE`／`bash build/MilBridge/tools/{pts-gap-count-check,pts-pages-guard,defect-registry-check,report-id-domain-check,handoff-machine-values-check,nl-intent-check}.sh`）。

---

## §0 结论速览（自包含）

1. ✅ **5 条真实现（非恒 `-10000`）＋ 该红必红**：新增导出 `FsDestroyPageBreakRecord`／`FsUpdateFinitePage`／`FsGetSubpageColumnBalancingInfo`／`SetScrollPosWrapper`／`GlobalDeleteAtomWrapper`（语义逐字照 `Pts.cs`／`NativeMethodsSetLastError.cs`，逐条见 §1）。**两极化（dlopen 探针现取）**：改前 5 名 `present=0/5`（缺符号）；改后 `present=5/5` 且 `[FSBATCH3-SELFTEST] mask=0x1f`＝5/5「正极真值 ∧ 反极必拒」；**反腿副本**（去掉 `FsDestroyPageBreakRecord` 的对象身份认领）⇒ `mask=0x1e`（**该位必红**）。
2. ✅ **诚实准入铁律**：本侧**只**是**自持对象**（页／子页／窗口状态）的作者；只收**无几何出参**、或出参**可由本侧真台账/自持状态推出**者（**生命周期/状态存取/行台账汇总**）；凡出参含**真几何**而无源者**一律不冒充**（`FsUpdateBottomlessSubpage`／`FsTransform*` 等）——**保持原样并如实划界**（见 §5）。
3. ✅ **在册数逐字段现算对账**：`PTSGAP=PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=3118bd1ce7d9604c exports=727`（`rc=0`）；`dead/artifact/w66pre16` 未动；`nm -D --defined-only` ＝ `exports.txt` ＝ **727**（逐名 `diff` **零差异**）。**5 条 = 缺口下降的条数**（`ops 47→42`）**逐字段一致**。
4. ✅ **门禁未回退**：`PTS_GUARD=PASS legs=2/2`／`PTS_COLORANCHOR=PASS k=24 hits=3`（两腿同）／`PTS_ENFE=PASS total=0`；`DEFREG=PASS`／`REPORTID=PASS`／`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0`；`NL_INTENT_RESULT=PASS capability=0 declared=yes anchors=3/3`。
5. ✅ **症状门 ＋ 帧面成对（只差 `.so`）**：腿 `before`（旧 `.so 969536ee1549ef39`）与 `after`（新 `.so 3118bd1ce7d9604c`）三帧**逐字节相同**（`AE=0`：`boot b21eb530afd3c66c`／`k23 10d0b9d54e649c10`／`k24 0bdb2dfd05952bc9`）、症状门逐格同（`alive=yes／app_rc=143／magenta=0／ink=480000／colors 386/636/1220／ns=…RichTextBoxDemo｜…FlowDocumentDemo`／`[HC-UNHANDLED]=0`／`entry point named=0`／`[FSBATCH3]` **两腿命中 0**）。
6. 🔴 **计数下降 ≠ 能力前进**（件头第 ① 条同口径）：5 条在**现产品路径未被调用**（两腿 `[FSBATCH3]` 命中 **0**；三帧 `AE=0`）⇒ 本增量把**缺符号**变成**有符号的真实现**，**页仍未被全绘**（症状门由腿读数给）。
7. ⚠️ **如实划界（具名 `NOINFO-WRAPPER-UNCOMPILED`）**：两条 `*Wrapper`（`SetScrollPosWrapper`／`GlobalDeleteAtomWrapper`）落在 `NativeMethodsSetLastError.cs` 的 **`#elif UIAUTOMATIONCLIENT || …`** 分支内（界 `:38`／`:93`），本仓所汇三程序集**均未定义**该符号 ⇒ **无托管调用方**（`T-A65` §4-W 现取）；本批仍**真实现**（符号可用 ＋ 按 Win32 语义真动作），**不**因无调用方就冒充。

---

## §0.5 方案（本趟**单方案**；未做多方案试探，上限 3 未用满，如实记）

| 方案 | 形态 | 现取读数 | 判决 |
|---|---|---|---|
| **1** | 只收**无几何出参**、或出参**可由本侧真台账/自持状态推出**的 5 条（`T-A65` §3 **甲类清单**，按其"实施代价低→中"顺序）；每条先认领后动作，反极必拒；附 native 逐条两极化自检 ＋ dlopen 探针 | `mask=0x1f`（正极＋反极 5/5）；反腿副本 `mask=0x1e` | ✅ **达** |

> 「出参含真几何而无源者」（`T-A65` §4 的**乙类 20 条**）被**显式排除**（不是"没来得及"）：本侧**不是** PTS 排版引擎的作者，几何是托管引擎的产物；本侧只作**自持对象**（页／子页／窗口状态）的作者 ⇒ 凡"要交出几何"的入口，本侧**无源** ⇒ 保持缺口、不冒充（`Pts.cs` 缺口**乙/丙/丁**三档见 `T-A65` §2 表）。**故无「方案 2／3」。**

---

## §1 逐条（件:行语义出处 ＋ 实现前后成对读数）

> 「实现前」＝ dlopen 探针 `present=0`（缺符号 ⇒ 托管一旦到达即 `EntryPointNotFoundException`）；「实现后」＝ `present=1` ＋ 自检正极真值（真返回值可现取）＋ 反极必拒（具名 `[FS_PAGE_GAP]`／`[FSBATCH3]`）。

| # | 入口（声明 件:行 → 调用点 件:行） | 诚实语义（逐字） | 实现前 | 实现后（正极 ⇒ 真值／反极 ⇒ 拒） |
|---|---|---|---|---|
| ① | `FsDestroyPageBreakRecord` `Pts.cs:3159-3162` → `PtsContext.cs:85`／`:524` | **无出参**。断页记录句柄 ＝ 本侧页对象内 `c_paras` **字段地址**（与 `FsCreatePageFinite` 的 `ppfsBRPageOut` 同源）；按**对象身份**认领后**失效该句柄**（置 `br_destroyed=1`）⇒ 二次调用必被拒。**不**声称"释放了真断页记录内存"（本侧无该实体，具名 `NOINFO=no-breakrec-memory(field-address-only)`） | `present=0` | 正极：`rc=0 v=BREAKREC-INVALIDATED` ∧ 同值再调 ⇒ `rc=-10000 reason=already-destroyed-breakrec`；反极：`NULL` ⇒ `reason=null-breakrec`、外来值 `0xDEAD` ⇒ `reason=unknown-breakrec`（`out=NO-OUTPUT`） |
| ② | `FsUpdateFinitePage` `Pts.cs:3118-3125` → `PtsPage.cs:457` | 承 `FsUpdateBottomlessPage`（`T-A19`）同形：出参 `FSFMTR`（3×`int`：`kstop`／`fContainsItemThatStoppedBeforeFootnote`／`fForcedProgress`，`Pts.cs:1141-1146`，**无几何**）＋ 断页记录句柄＝页字段址；**永不假成功**（只有**页在册**才返 0）；**不**声称"页被重新排版"（具名 `NOINFO=fsupdatefinitepage-scope-native-owned-state`） | `present=0` | 正极：`rc=0 kstop=0`（＝本页对象自持 `result`）∧ `brk=0x…e248`（＝本页 `&c_paras`，可再被 ① 销毁）；反极：未知页 ⇒ `reason=unknown-page`、`NULL` 出参 ⇒ `reason=null-out`，且 `FSFMTR=NOT-ACHIEVED(16)`、`brk=NULL` |
| ③ | `FsGetSubpageColumnBalancingInfo` `Pts.cs:3283-3290` → `PtsHost.cs:2521`／`:3213` | 出参（`fswdir`／行数／行高和／最小行高）**只**取自本侧**真行台账** `fl_line[]`（`T-A28`，由 `pfnFormatLine` 真返回值入账）：**对内容子树递归汇总**（同 `FsGetSubtrackColumnBalancingInfo` 谓词 `wpf_pts_fl_usable`）；`fswdir` 取**本侧恒 ltr(0)**（承 `wpf_pts_fstextdetailsfull.fswdir` 同一约定，具名 `NOINFO=FSWRITINGDIR`） | `present=0` | 正极：`rc=0 fswdir=0 nlines=2 dvrSumHeight=31 dvrMinHeight=15 src=content-subtree:fl_line[]`；反极：无台账子页 ⇒ `reason=no-line-ledger`（四出参**先清 0**）、伪值 ⇒ `reason=unknown-subpage`、`NULL` 出参 ⇒ `reason=null-out` |
| ④ | `SetScrollPosWrapper` `NativeMethodsSetLastError.cs:89-90`（**非编译分支**） | 本侧**有窗口模型**（`win32_core.c`；`wpf_window.scroll_pos[2]` 自持位置位）。承 Wrapper 族形制（`GetWindowLong*Wrapper` 同办：**先 `SetLastError(0)`**）：成功 ⇒ 返回**旧位置**；未知 `hwnd` ⇒ 返 0 ＋ `SetLastError(ERROR_INVALID_WINDOW_HANDLE=1400)`；`nBar` 越界 ⇒ 返 0 ＋ `SetLastError(87)`（**不静默成功**） | `present=0` | 正极：同 `hwnd` 连调 ⇒ `old=0`（首次）→ `old=100`（第二次返回第一次设的值）；反极：未知 `hwnd` ⇒ `set_last_error=1400`、`nBar=9` ⇒ `set_last_error=87`（`NOINFO=WRAPPER-REDRAW(no-scrollbar-visual)`） |
| ⑤ | `GlobalDeleteAtomWrapper` `NativeMethodsSetLastError.cs:46-47`（**非编译分支**） | **新立**一张进程内**全局原子表**（语义明确、无外部源依赖）；**不**与窗口**类原子表**（`wpf_class_find_atom`，`win32_core.c:341`）共用命名空间（具名 `NOINFO=ATOM-NAMESPACE`）。Win32 语义：成功 ⇒ 返回该 `atom`（引用计数减 1，减到 0 即移除）；失败 ⇒ 返 **0** ＋ `SetLastError(ERROR_INVALID_HANDLE=6)`（**不**用 `-10000`：Win32 失败返回就是 0） | `present=0` | 正极：真 atom `0xc000` ⇒ `ret=0xc000 ref_left=0` ∧ 再删 ⇒ `ret=0`＋`set_last_error=6`；反极：不存在 atom ⇒ `ret=0`＋`set_last_error=6`（具名 `NOINFO=ATOM-ADD-NOT-EXPORTED`） |

> 语义出处铁律：每个入口的**行为形状**由上游 `DllImport` 声明（行号见表）＋ 其**唯一/主调用点**（行号见表）共同界定；本侧不发明协议（值域常量逐字照 `Pts.cs`／`NativeMethodsSetLastError.cs`）。

---

## §2 改动（逐处）

### 2.1 `win32_pts.c`：5 条真实现 ＋ 自检 ＋ 只读桥接
- **struct 加字段**：`struct wpf_pts_fsp` 增 `int br_destroyed;`（① 的"断页记录句柄已失效"位；`calloc` 初值 0 ⇒ 无副作用）。
- **5 条导出**：置于 `WpfLinuxWin32_PtsFsBatch1Gap` 之后（`WpfLinuxWin32_PtsGapSelfCheck` 之前），共用一个具名失败面助手 `wpf_pts_b3_gap()`（`[FS_PAGE_GAP] rc=-10000 reason=… entry=… out=<失败面出参形状>` —— `outstate` **逐条**写形状：① `NO-OUTPUT`｜② `FSFMTR=NOT-ACHIEVED(16) brk=NULL`｜③ `fswdir=0 nlines=0 dvrSum=0 dvrMin=0`）与成功面 `[FSBATCH3] …`；①②③ 的认领复用既有 `wpf_pts_sp_claim_track`（子页）／新的页身份谓词 `wpf_pts_b3_page_claim`（**按对象身份**，NULL／外来值／已销毁值一律拒）。
- **逐条两极化自检** `WpfLinuxWin32_PtsFsBatch3SelfCheck()`：自建 doc 上下文 ＋ 1 页夹具（走真 `FsCreatePageFinite`）＋ 2 子页夹具（内容树 root⇒叶，叶具真行台账 2 行/16+15）＋ 1 窗口夹具（`wpf_window_add`）＋ 1 原子夹具，跑「正极真值 ∧ 反极必拒」，返回 5-bit `mask`；**收尾真销毁全部夹具对象并断言活数回 base**（泄漏 ⇒ `-1`，**不算绿**）；自检只改自己的对象与自己的计数（出口 save/restore `g_pts_b3_*`／`g_pts_fsp_fin_*`／`g_pts_sp_*`）。
- **只读桥接**（导出，供探针/判据现取）：`WpfLinuxWin32_PtsFsBatch3{SelftestMask,SelfCheck,Ok,Gap}`。
- **反腿开关**：**无**（反腿以**副本 `python3` 改**构造，主链产物**一个字节不带**反腿分支 —— 见 §3.3）。

### 2.2 `win32_internal.h`：`struct wpf_window` 增 `int scroll_pos[2];`
`SetScrollPosWrapper` 的位置位（`SB_HORZ(0)`／`SB_VERT(1)` 各一格）；`wpf_window_add` 用 `calloc` ⇒ 初值 0；**加在结构尾** ⇒ 既有字段偏移一字不动（`win32_core.c` 无 `sizeof(wpf_window)` 断言，现取）。

### 2.3 登记面 `tools/pts-gap-decl.txt`
DECL 行 `tool/ops/impl/so16/exports` 五格更新（`54/42/42/3118bd1ce7d9604c/727`）；其下**只增**一段 `⚠️ 波 T-A66 重锚` 追注（照 `T-A64` 重锚体例）：述 5 条、诚实准入铁律、计数逐字段、`so16` 换代、判据成对读数、两极化（探针 mask）＋ `NOINFO-WRAPPER-UNCOMPILED` 划界。

### 2.4 复述位现值位（只改数）
`docs/ROUTES.md`（`:262`／`:403`（`TASK-0720` 现算块）／`:550`）／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（两处现值位）／`src/WpfGfx.Linux.Native/src/win32_classification.c` 的现值位 `59/47/47` ⇒ **`54/42/42`**。`build/MilBridge/HANDOFF-NEXT.md`：`§3` 现值位随动 ＋ **文件尾只增**一行机器值契约 `cell=#1／#3`（`inputs_fp` 因写域件 `win32_pts.c`／`win32_internal.h`／`pts-gap-decl.txt`／`win32_classification.c` **在覆盖面内** ⇒ 必然位移 `8b7ba6f0…→b266abcb…`）。
- **历史行原文保留** —— 它们**自引旧代锚 ＋ dated 措辞**，判据件按裁定九**不参与现值判定**（现取 `PTSGAP_HISTORICAL=n=11`）。

### 2.5 为什么**不是**改 `win32_core.c`／`win32_misc.c`
本增量**全在 `win32_pts.c` ＋ 一个结构字段（头）**：④ 的窗口位置位落在**本侧窗口模型**（结构字段），⑤ 的原子表是**本批新立**的独立实体。⇒ **未碰** `win32_core.c`／`win32_misc.c` 的任何函数体（**零回归面更大**）；`GlobalDeleteAtomWrapper` 不放进 `win32_misc.c` 的 `Global*` 家族的理由是**本批合一处实现**（同一增量、同一自检、同一 mask），**如实登记**为**体例选择**（不是"放错文件"）。

---

## §3 成对读数（**同装置 `:231`**；证据 `~/tA66-work/`）

### 3.1 探针（dlopen ＋ dlsym ＋ 自检；`present` 与 `mask` 本席现取）

| 读数 | **改前**（旧 `.so 969536ee1549ef39`） | **改后**（新 `.so 3118bd1ce7d9604c`） |
|---|---|---|
| 5 名 `present` | **0/5**（缺符号） | **5/5** |
| `WpfLinuxWin32_PtsFsBatch3SelfCheck` 符号 | 0 | 1 |
| `PROBE SELFTEST_MASK` | （无符号） | **`0x1f`**（destroy_brk／update_finite／subpage_bal／scrollpos／atom ＝ 1） |
| 判词 | — | `[FSBATCH3-SELFTEST] mask=0x1f … legs=5/5(POS+REJECT)` |

**正极真值（`mask` 的承重读数，逐条可现取）**：① `FsDestroyPageBreakRecord` ⇒ `v=BREAKREC-INVALIDATED` ∧ 同值再调 `reason=already-destroyed-breakrec`；② `FsUpdateFinitePage` ⇒ `kstop=0`（＝本页 `result`）∧ `brk=0x…e248`（＝`&c_paras`，可再被 ① 销毁）；③ `FsGetSubpageColumnBalancingInfo` ⇒ `nlines=2 dvrSumHeight=31 dvrMinHeight=15 src=content-subtree:fl_line[]`；④ `SetScrollPosWrapper` ⇒ `old=0`→`old=100`（第二次返回第一次设的值）；⑤ `GlobalDeleteAtomWrapper` ⇒ `ret=0xc000 ref_left=0` ∧ 再删 `ret=0`。

### 3.2 反极性（该红必红）
每条入口的**反极腿**在自检内**同一谓词**判（§1 表"反极"列）：`NULL`／外来值（`0xDEAD`）／已失效值／未知上下文 一律 `rc=-10000` ＋ 具名 `[FS_PAGE_GAP]`，出参**只写确定的非语义值**（① 无出参；② `FSFMTR=NOT-ACHIEVED(16)`、`brk=NULL`；③ 四出参清 0）；④⑤ 按 Win32 约定返 **0** ＋ 非零 `SetLastError`。

### 3.3 反腿副本（**证明自检真有牙**）
以 `python3` 造**仓外副本** `~/tA66-work/badrepl/`：仅去掉 `FsDestroyPageBreakRecord` 的**对象身份认领**（对任意入参也返 0）⇒ 同一探针现取 **`mask=0x1e`（`destroy_brk=0`）** ⇒ 该位**必红**、自检**不是恒真**。**主链产物不含任何反腿分支**（一个字节不受影响）。

### 3.4 腿（`run-pts-pages-legs.sh`；两条腿**只差权威 `.so`**，其余全同）

| 腿 | 权威 `.so` | 证据目录 | `LEGS_RUNNER` |
|---|---|---|---|
| `before` | `969536ee1549ef39`（改前） | `~/tA66-work/legs/before/` | `PASS requested=2 obtained=2 refused=0` |
| `after` | `3118bd1ce7d9604c`（改后） | `~/tA66-work/legs/after/` | `PASS requested=2 obtained=2 refused=0` |

> ⚠️ **如实记（`after` 腿重取一次）**：首次 `after` 腿在 `.so 209db309c86bc4d4` 上跑（LEGS_RUNNER=PASS）；随后本席**同趟**把 `wpf_pts_b3_gap()` 的失败面留痕文本由固定的 `out=UNWRITTEN bytes=0` 改成**逐条的 `out=<形状>`**（② 失败面**确有**写"未达成"、③ **确有**清 0 ⇒ 旧文本对 ②③ 是**假话**）⇒ `.so` 换代。为让"权威件 ＝ 腿件"逐字成立，`after` 腿在 `3118bd1ce7d9604c` 上**重取**（本表所载）；两次 `after` 的三帧与症状门**逐字节相同**（仅日志文本变），故重取不改任何判词。

**症状门（逐腿现取）**：

| 量 | `before` | `after` |
|---|---|---|
| `k24` | `alive=yes app_rc=143 magenta=0 colors=1220 ns=…FlowDocumentDemo ae=220019 ink=480000` | **同** |
| `k23` | `alive=yes app_rc=143 magenta=0 colors=636 ns=…RichTextBoxDemo ae=136292 ink=480000` | **同** |
| `boot` | `colors=386 magenta=0 ink=480000` | **同** |
| `[HC-UNHANDLED]` / `entry point named` / `[FSBATCH3]` | `0` / `0` / `0` | `0` / `0` / **0**（5 条**未被调用**） |
| `PTS_COLORANCHOR` | `PASS k=24 hits=3`（`GhostWhite=9794 Beige=910 DarkGreen=44 LightGoldenrodYellow=5830`） | **PASS hits=3**（同值） |
| `PTS_GUARD` | `PASS legs=2/2` | **PASS legs=2/2** |
| `PTS_ENFE` | `PASS total=0` | **PASS total=0** |

**帧面成对（本席自算，只读 PNG）**：`AE(before,boot)=0`／`AE(before,k23)=0`／`AE(before,k24)=0`（`fr_sha` 逐格相等：`boot b21eb530afd3c66c`／`k23=10d0b9d54e649c10`／`k24=0bdb2dfd05952bc9`）⇒ **5 条入口在现产品路径未被调用 ⇒ 逐字节零位移**（这正是本节要证的事，不是"没测"）。

### 3.5 门禁六件（现取）

| 门 | 读数 | rc |
|---|---|---|
| `nm==exports` | `nm -D --defined-only` ＝ **727** ＝ `exports.txt` 行数；**逐名 `diff` 零差异** | 0 |
| `PTSGAP` | `PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=3118bd1ce7d9604c exports=727` | 0 |
| `HANDOFF_MV` | `PASS cells=9 equal=8 manual=1 mismatch=0` | 0 |
| `DEFREG` | `PASS declared=225 route_ids=225`（`DECLDRIFT=1 keys=KD`：本趟改 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 现值位 ⇒ 该 route 件离开声明锚；`defect-registry-declared.tsv` 在**黑名单**内 ⇒ **未重发**，如实记） | 0 |
| `REPORTID` | `PASS files=341 ids=2257 declared=225`（本件落盘前 `341` ⇒ 落盘后 `342`，`+1` 即本件） | 0 |
| `NL_INTENT` | `PASS capability=0 declared=yes anchors=3/3`（`Nl*` 6 名**一个都没导出**） | 0 |

---

## §4 逐件 `sha16`（现取）

| 件 | 改前 | 改后 |
|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `c80a03e9633641a7`（674995 B） | **`11a3f6ba49f3f22c`**（703908 B） |
| `src/WpfGfx.Linux.Native/src/win32_internal.h` | `adfa3fcd8b926d6a` | **`79b75123d2a51fe6`** |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so`（**非仓内件**） | `969536ee1549ef39`（490296 B） | **`3118bd1ce7d9604c`**（503336 B） |
| `src/WpfGfx.Linux.Native/bin/exports.txt`（**非仓内件**） | `20b6d9aa3125bbc4`（718 行） | **`d925266b9acd9847`**（727 行） |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `d78e5b0c65dc1e89` | **`e19699dbe4c9766b`** |
| `docs/ROUTES.md` | `9ba07aec3cc39910` | **`27171c049f561551`** |
| `README.md` | `edfb3b358c516c0a` | **`a0cd9a256df17ea0`** |
| `docs/unimplemented.md` | `9056aaa690aed27a` | **`7345d52d7bba7f89`** |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `883231e1ba36dea6` | **`a6d4fe9737b62ed0`** |
| `build/MilBridge/HANDOFF-NEXT.md` | `2cbb3af789ba1e61` | **`30e0f7fe3215b413`** |
| `src/WpfGfx.Linux.Native/src/win32_classification.c` | `252fa66042600f78` | **`f3eb4d1f0e6a9bf6`** |
| `docs/WAVE66-PREREGISTRATION.md`（**冻证据**） | `bf6b683d94549087` | **未变** |
| `build/PresentationFramework.Linux/reapply-patches.py`（生成器） | — | **未变** |
| 反腿副本 `~/tA66-work/badrepl/bin/libwpfwin32.so`（**仓外**） | — | `8343f23bfb72b4d7`（`mask=0x1e`） |

---

## §5 诚实边界（防读宽，逐条）

1. **"5 条真实现"只主张"符号在册 ＋ 按在册语义真动作 ＋ 反极必拒"，不主张"排版能力前进"**：5 条在现产品路径**未被调用**（§3.4，`[FSBATCH3]` 两腿命中 0、三帧 `AE=0`）⇒ 页仍**未全绘**。**计数下降 ≠ 能力前进**（件头第 ① 条）。
2. **① "销毁断页记录"≠"释放真记录内存"**：本侧断页记录**没有独立实体**（它就是页对象 `c_paras` 字段的地址）⇒ 本入口的语义落成**按对象身份认领后失效该句柄**（`br_destroyed=1`）；具名 `NOINFO=no-breakrec-memory(field-address-only)`。
3. **② 不冒充"页被重新排版"**：`FsUpdateFinitePage` 只刷新**本模块自持**的页对象字段（`sect`／`br_destroyed`／`result` 回写出参），**不**调驱动探针、**不**声称"页会可见变化"；具名 `NOINFO=fsupdatefinitepage-scope-native-owned-state`。`FSFMTR.kstop` 成功面取本页自持 `result`（与同侪 `FsCreatePageFinite`／`FsCreatePageBottomless` **同源**）。
4. **③ 行高的几何来源已具名**：`dvrSumHeight`／`dvrMinHeight` 是**本侧约定**（`dvrAscent+dvrDescent`，与 `fl_vr_start` 同源），且**只在** `wpf_pts_fl_usable` 成立（真行台账）时才给 ⇒ 具名 `NOINFO=FSGEOMETRY-LAYOUT`；`fswdir` **只**报本侧恒 ltr(0) ⇒ 具名 `NOINFO=FSWRITINGDIR`（**不**冒充 RTL 方向推断）。
5. **④ "位置状态存取"≠"滚动条视觉"**：`bRedraw` 本侧无重绘面 ⇒ 具名 `NOINFO=WRAPPER-REDRAW(no-scrollbar-visual)`；**只**主张"本侧窗口模型的位置状态存取"。
6. **⑤ 原子表是**新立**的独立实体（**不**与类原子表共用）**：具名 `NOINFO=ATOM-NAMESPACE(not-class-atoms)`；公开的 `GlobalAddAtom*` 导出**不在本批清单内** ⇒ 表的填充只经内部等价体 `wpf_pts_b3_atom_intern`（供自检夹具用；具名 `NOINFO=ATOM-ADD-NOT-EXPORTED`）。
7. **④⑤ 无托管调用方（`NOINFO-WRAPPER-UNCOMPILED`）**：两条 `*Wrapper` 在 `#elif UIAUTOMATIONCLIENT…` 非编译分支内，本仓三程序集均未定义该符号（`T-A65` §4-W 现取）⇒ 本批**只**把"缺符号"变成"有符号的真实现"，**不**声称任何产品路径被覆盖。
8. **被排除的入口是"如实划界"不是"遗漏"**：`FsUpdateBottomlessSubpage`／`FsFormatSubtrack*`／`FsQuery*ColumnList`／`FsGet*FootnoteInfo`／`FsTransform*` 等（`T-A65` §4 乙类 20 条）**仍留在缺口名单**（出参含真几何/变换语义，本侧**无源**）。
9. **`bin/*` 非仓内件**：`src/WpfGfx.Linux.Native/bin/` 在 `.gitignore` ⇒ 该件由 `build-shim.sh --symbols` **每次重产**；`nm==exports` 是**构建不变量**（不是"我们手工对齐了一份表"）。
10. **自检只改"自己的对象与自己的计数"**：`WpfLinuxWin32_PtsFsBatch3SelfCheck()` 收尾真销毁全部夹具对象并**断言活数回 base**（否则返 `-1` ＝**不算绿**）；出口 save/restore 自己动过的计数（`g_pts_b3_*`／`g_pts_fsp_fin_*`／`g_pts_sp_*`）；它**不**改任何产品状态／台账。
11. **反腿以副本构造**（`~/tA66-work/badrepl/`，仓外）：主链源码**不含**反腿宏/分支 ⇒ 反向不引入产品面分支。

---

## §6 遗留（下一增量具名靶）

- **`Fs*` 族**：`T-A61`（首批 8）＋ `T-A66`（甲类 5）已做；余量见 `build/MilBridge/P1-tail2-gapbatch1-impl-report.md` §6 与 `T-A65` §2 表的**乙 20／丙 6／丁 16** 三档。
- **甲类清单已清**（`T-A65` §3 的 5 条本趟全做）⇒ 下一靶在**乙类**（须先有**真几何源**）或**丁类**（须"内容层那一波"新立 `C2`/`C4`）；**丙类**（`Nl*` 6）按在册语义**有意降级**、不许导出。
- **`declared.tsv` 的收波随动**：由不在本任务黑名单内的收波步骤完成。

---

`P1-TAIL2-GAPBATCH3 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ c642aede38f00092（末行＝本行）`

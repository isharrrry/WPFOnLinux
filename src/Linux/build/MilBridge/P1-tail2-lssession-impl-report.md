# `P1-tail2` · `T-A72` · **LS 会话进链（`PRECOND-LS-SESSION-DRIVER`；`W` 合取①）＋ 契约 `C2` 的 `ploc` 一半**（`TASK-0307` 增量）—— 实现报告

**判决**：把在册前置 **`PRECOND-LS-SESSION-DRIVER`**（`build/MilBridge/P1-ls-callback-face-recon.md:85`：「⇒ 新增具名前置：**`PRECOND-LS-SESSION-DRIVER`** —— 一旦实现 LS，本侧要成为**重入方**（托管→我们→托管），其寿命/重入口径**不在 `t166` 的射程内**」）与契约 **`C2` 的 `ploc` 一半**（`build/MilBridge/P1-ls-provenance-contract.md:70`：「LS 会话标识（`plsrun` 起点 或 `LoCreateContext` 的 `ploc`）｜**宿主 + LS**｜❌ **不存在于我们的链上**……**须新立**｜❌ **不能** ⇒ 只能**接收并保管**」；`build/MilBridge/P1-tail2-dingrecon.md:91` §3.2 第 1 条：「**LS 会话进链**：`LoCreateContext` 的 `ploc` 与文本段落 `nmp` 在本侧**同一窗内**可观测」）落地成 native 侧一条**会话↔段落进链台账（按对象身份可寻址）＋ 逐条只读回读面（会话身份／所属段／回调面指纹／两结构指针一致性）＋ 两极化自检**：**托管侧**（生成器重产件 `WpfLinuxLsSessionProbe.Linux.cs` ＋ `PtsCache.Linux.cs` 的 `CreatePTSContext` 一处 `NoteContext` ＋ `TextParaClient.Linux.cs` 的 `ValidateVisual` 一处 `Feed`）在**同一窗内**把 **LS 会话身份**（`LoCreateContext` 的 `ploc`）与**文本段落**（`_paraHandle`）交给 native；native **当场按对象身份认领会话**（`wpf_pts_loc_find`）—— 认不出 ⇒ **诚实拒绝**（`not-in-chain`，表内不出现该条）—— 并把**回调面指纹**（`T-A68` 的窗内值化面 ＋ 对两副本算的 FNV-1a 64）与**两结构指针**（`LsContextInfo`／`LscbkRedefined`）逐格现取，所属段按**同一段身份**接到 `T-A69`（内容源）／`T-A71`（进链）两本台账（`para_link` 为「一一对应」的机器读数），随后托管**回读并逐格对拍**。**真腿现取（`after`）**：`[LSSESS] ctx … live=1/2/3` **×3**（互异 `ploc` **3**）＋ `[LSSESS] mgd … rc=0 cbf_state=2 nonzero=26 min=8/9 redef_nz=3 layok=1 fp=… ptr=1 link=1 state=2 mism=0 v=LS-SESSION-IN-CHAIN` **×25** ＋ native `[LSSESS] rx=OK …` **×25**（`rx_reject=0`／`distinct_ploc=3`／`distinct_para=25`）。**两极化**：探针 `[LSSESS-SELFTEST] mask=0x0f`（4/4）；外部反腿 `NOCHAIN feed=-10000 find=-1`；**反腿副本**（`not-in-chain` 闸由"拒"改成"**只记不拒**"＝静默半通形态）⇒ `mask=0x03`、`NOCHAIN feed=0 find=-1 COUNT=1`、`PROBE_RC=1`（**该红必红**）；**反极腿**（`WPF_LSSESS_FEED=0`）⇒ 本侧 `[LSSESS]` 行 **0 条**。**零回归**（三腿四帧**逐字节同**；`PTS_GUARD=PASS`／`PTS_COLORANCHOR=PASS hits=3`／`PTS_ENFE=PASS total=0`）。**导出面**：`exports 798→824`（逐名 **+26**、**无消失**），`nm==exports`；`PTSGAP`／`DEFREG`／`REPORTID`／`HANDOFF_MV` rc=0。🔴 **如实划界（本件的核心判决）**：**进链 ≠ 排版** —— 本条**只**判「会话身份**在链上可认领** ∧ 所属段在**两本台账里可解析** ∧ **回调面指纹**与**两结构指针**可逐格现取 ∧ **可两极化**」；它**不**填任何几何／行盒／`cLines`／`dcp` 区间，也**不**主张「LS 引擎真用该会话排了该段」（本移植**绕过 LS 造型**）⇒ `PRECOND-NO-LINE-BREAKER`／`C2` 的 `plsrun` 那一半**仍在册**，`W` 整体**未解除**。

- **读时**：`2026-10-02T00:0x–00:1x+0800`（本席现取；各条另注）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`（**未 `git add/commit/push`**）；开工 `HEAD=d7d592b`（`T-A70`／`T-A71` 结账后的**干净树**，`git status --short` 现取仅 `?? build/MilBridge/tasks-tail2/T-A72.md`）。
- **改前件备份（仓外 `~/tA72-work/bak/`，`cp -p`，取在**任何写之前**）**：`win32_pts.c`（`6ad1500b59cd7cf0`／790224 B／10710 行）／`bin/libwpfwin32.so`（`53116d7456f62c44`／533832 B）／`bin/exports.txt`（`3fc15b59b35739f3`／798 行）／`tools/pts-gap-decl.txt`（`a9eb06731f1f3b42`／649 行）／`build/PresentationFramework.Linux/reapply-patches.py`（`0fdbadc739470b47`／172833 B）／其重产件（`bak/generated/` 全套 22 件）／`PresentationFramework.dll`（`7cfcfa8c1f024b35`）／`docs/ROUTES.md`（`9e126bd9443c8c65`／1132 行）／`build/MilBridge/HANDOFF-NEXT.md`（`79cdfa566464cff9`／771 行）。
- **写域（逐件）**：`src/WpfGfx.Linux.Native/src/win32_pts.c`（**加一段 `T-A72` 块**：会话↔段落进链台账 ＋ 逐条只读回读面 ＋ 两极化自检）／`src/WpfGfx.Linux.Native/bin/exports.txt`（**构建重产**，非手改）／`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（DECL 行 `so16`／`exports` 跟权威件换 ＋ 只增一段 `T-A72` 重锚）／**生成器** `build/PresentationFramework.Linux/reapply-patches.py`（新增 `LSSESS_PROBE_FILE`／`LSSESS_PROBE_TEXT` ＋ `PTSCACHE_E7`／`PTSCACHE_E8` 两处接线 ＋ `TPC_E_VV_REPL` 一处调用 ＋ `materialize_derived()` 写新件 ＋ `PATCH_C` 一行 `<Compile Include>`）／**其重产件**（`WpfLinuxLsSessionProbe.Linux.cs` **新建件**、`PtsCache.Linux.cs`、`TextParaClient.Linux.cs`、`PresentationFramework.Linux.csproj`）／**复述位现值位**（`docs/ROUTES.md` `TASK-0307` 行加一条 dated 结账；`build/MilBridge/HANDOFF-NEXT.md` 文件尾机器值契约追写）／**新建载体** 本件。
- **未改**（如实体例）：`docs/WAVE66-PREREGISTRATION.md`（冻证据 `w66pre16=bf6b683d94549087` 未动）；`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`src/WpfGfx.Linux.Native/src/win32_classification.c`（本趟**未移动**它们所持的 `tool/ops/impl` 三格 ⇒ `PTSGAP` 判据**要求**它们**不动**，见 §4）；`build/MilBridge/tests/PtsPagesProbe/evidence/**`（**在册冻证据未动**）；`bin/libwpfwin32.so`／`bin/exports.txt`／`build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` 属**构建产物**（非仓内件）。
- **黑名单遵守**：未动 `build/MilBridge/tools/**`（**只读跑**判据件）／`verify-all.sh`／`build/close-wave.sh`／`build/shims/**`／`upstream/**`（只读）；**未跑**整趟 `verify-all`；未改相位位；未 `git add/commit/push`。⚠️ 如实记：`build/MilBridge/tools/defect-registry-declared.tsv` 在本趟 `git status` 里呈 `M` —— 那是**跑判据件自身**的副产（`--emit`），**本席未手改其内容**（该 `M` 与 `T-A71` 趟同源，见 `T-A71` 报告同位置）。
- **重活**：**3 趟 native 构建**（主链 2 ＋ 仓外反腿副本 1）＋ **1 趟托管构建**（`0 警告 0 错误`，`25.3 s`）＋ **1 趟跑器**（`before`／`after`／`rev`，共 **6 条腿**），全走 `bash ~/heavy-slot.sh --min-avail 2000 --max-hold 1800/2400 --wait 3600 -- <cmd>`（逐趟 `HEAVYSLOT=ACQUIRED/MEMOK/RELEASED rc=0`）；进程只按 PID；显示位只用跑器自分配的号（`DISPLAY_PICK :231`）；禁 `sleep` 轮询；写前 `cp -p`；`temp+rename`（生成器 `_write_atomic`；本席改文档亦走 `tmp+os.replace`）；模式守恒。
- **口径**：一切读数**本席现取**（`sha256sum`／`nm -D --defined-only`／`diff`／`grep -c`／`gcc` 编译的 `dlopen` 探针 `~/tA72-work/probe`／只读跑 `bash build/MilBridge/tools/{pts-gap-count-check,pts-pages-guard,defect-registry-check,report-id-domain-check,handoff-machine-values-check}.sh`）。凡引他件处一并标注。

---

## §0 结论速览（自包含）

1. ✅ **「LS 会话进链」= 真进链（现取）**：`after` 腿 `app_g1.log` 里 `[LSSESS] rx=OK … state=BOUND v=LS-SESSION-IN-CHAIN` **25 条** ⇒ 托管在真应用里把 **25 个文本段落**与它们所属的 **LS 会话**在**同一窗内**交进 native 且**逐个按对象身份认领成功**；`before` 腿 **0 条**（旧件无此面）。
2. ✅ **会话数／段数／回调面指纹（现取）**：`[LSSESS] ctx …` **×3**（互异 `ploc` **3** ⇒ **会话数 3**，与 `T-A68` 的 3 次 `LoCreateContext` **逐值相符**）；`[LSSESS] mgd` **×25**（**段数 25**，互异 `para` 25）；**回调面指纹** 3 枚（`2314400fd74c521e`／`41d93354fc6a22f4`／`22c47f32cca999aa`，**同一会话内恒同值**、跨会话互异 ⇒ 可证伪）；`nonzero=26 min=8/9 redef_nz=3 layok=1` 与 `T-A68` 真腿读数**逐值相符**。
3. ✅ **两结构指针一致性（现取）**：每行 `info=…`／`redef=…` **非空** ∧ `ptr=1`（`PtrOk` # 两结构指针非空 ∧ **会话句柄仍指回同一个在册对象** ∧ 该对象上的两指针与登记值**逐一相等**）**25/25**。
4. ✅ **与 `T-A69`／`T-A71` 一一对应（现取，逐段对拍）**：同一批 25 段的 `para` 集合**交集 25／25**、只在 `LSSESS` **0**；`src_slot == chain_slot` **25/25**、`link=1` **25/25**、`mism=0` **25/25**。
5. ✅ **两极化（该红必红）**：① 探针 `[LSSESS-SELFTEST] mask=0x0f`（4/4：正极 `BOUND`∧指纹逐格相符／`UNBOUND≠NONE`／反极必拒／**同段被第二个会话认领必拒**）＋ 幂等复算同值；② **反腿副本**（`~/tA72-work/replica-native/bin/libwpfwin32.so 73096e93a832cf90`，把 `not-in-chain` 闸由"拒"改成"**只记不拒**"＝静默半通形态）⇒ `mask=0x03`（bit2／bit3 灭）、外部反腿 `NOCHAIN feed=0 find=-1 COUNT=1`、`PROBE_RC=1`（**该红必红**）；③ **反极腿**（`WPF_LSSESS_FEED=0`，同一权威件）⇒ `[LSSESS]` 行 **0 条**。
6. ✅ **零回归**：`.so 53116d7456f62c44（改前）→ 630cefb6c7bdf0f0（改后）`／`pf 7cfcfa8c1f024b35 → 94a73efe3bc68808`；三腿（`before`／`after`／`rev`）四帧**逐字节相同**（`AE=0`；`boot b21eb530afd3c66c`／`k23 10d0b9d54e649c10`／`k24 0bdb2dfd05952bc9`／`last 10d0b9d54e649c10`）、症状门逐格同；`PTS_GUARD=PASS legs=2/2`／`PTS_COLORANCHOR=PASS k=24 hits=3`／`PTS_ENFE=PASS total=0` **未回退**。
7. ✅ **门禁四件（现取）**：`nm -D --defined-only` ＝ `exports.txt` ＝ **824**（逐名 `diff` 零差异；**+26 无消失**）；`PTSGAP=PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=630cefb6c7bdf0f0 exports=824`（rc=0）；`DEFREG=PASS declared=225 route_ids=225`（rc=0）；`REPORTID=PASS files=347 ids=2257 declared=225`（rc=0，本件落盘后 `+1`）；`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0`（rc=0）。
8. 🔴 **如实划界（本件的核心判决）**：本条**只**判「**会话身份在链上可认领 ∧ 所属段在两本台账里可解析 ∧ 回调面指纹与两结构指针可逐格现取 ∧ 可两极化**」。它**不**判「排版前进」、**不**判「`W` 解除」—— `PRECOND-NO-LINE-BREAKER`／`C2` 的 `plsrun` 那一半**仍在册**；「**会话进链**」与「**排版**」是两件事（三腿四帧逐字节同 ⇒ **零像素位移**）。

---

## §1 「LS 会话进链」的**准入判据**（现取：件:行 ＋ 满足／不满足）

> **判据一律逐字引自**已登载的判据件（件:行）；行号只保证本次有效（内容锚原文一并给）。

### 1.1 在册出处（逐字）

| 角色 | 件:行 | 现取原文（要点） |
|---|---|---|
| **前置本体（本条的靶）** | `build/MilBridge/P1-ls-callback-face-recon.md:85` | 「⇒ 新增具名前置：**`PRECOND-LS-SESSION-DRIVER`** —— 一旦实现 LS，本侧要成为**重入方**（托管→我们→托管），其寿命/重入口径**不在 `t166` 的射程内**。」 |
| **契约 `C2`** | `build/MilBridge/P1-ls-provenance-contract.md:70` | 「**C2**｜LS 会话标识（`plsrun` 起点 或 `LoCreateContext` 的 `ploc`）｜**宿主 + LS**｜❌ **不存在于我们的链上**……**须新立**｜❌ **不能** ⇒ 只能**接收并保管**」 |
| **`W` 合取①** | `build/MilBridge/P1-tail2-dingrecon.md:91`（§3.2） | 「**LS 会话进链**：`LoCreateContext` 的 `ploc` 与文本段落 `nmp` 在本侧同一窗内可观测」 |
| **准入的形式条件** | `P1-tail2-dingrecon.md:98` | 「**当且仅当** `W` 每项在同一趟腿上有**可现取的真读数／具名留痕**（`P10`）时，"内容层那一波"＝**已落地**。」 |
| **`T-A67` 的现取修正** | `P1-tail2-dingrecon.md:103`（§3.3-1） | 「**`C2` 的 `ploc` 一半，本侧**已有**。** 现取：`LoCreateContext`／`LoDestroyContext` **本侧已真实现并已导出**（`win32_pts.c:4238`／`:4259`…）」 |
| **源在谁手上（`P9` 边界）** | `P1-layout-content-criteria.md:146` | 「**源在宿主侧**……本件只判"**取它要开新面**"」 |
| **粒度（承契约）** | `P1-ls-provenance-contract.md:100` | 「粒度：**单段落**」（本件不宣布跨页/整页结论） |

⇒ **本条把"LS 会话进链"判据化（写死）为五条合取**：**(a) 台账可寻址**（按**段身份**查得；**会话身份**必须是本侧登记表里的**真对象**才收，否则诚实拒绝）；**(b) 四格逐条现取**（**会话身份／所属段／回调面指纹／两结构指针**）；**(c) 与 `T-A69`／`T-A71` 一一对应**（同段身份 ⇒ 两本台账都可解析，且逐段相符）；**(d) 两极化**（**会话不入链 ⇒ 必拒**；**同段被第二个会话认领 ⇒ 必拒**；`WPF_LSSESS_FEED=0` ⇒ 0 条）；**(e) 留痕**（`[LSSESS]` 具名行）。

### 1.2 逐条现取（满足／不满足）

| # | 判据 | 现取读数（`after` 腿／探针） | 判定 |
|---|---|---|---|
| **(a) 可寻址＋进链有牙** | 会话身份必须能在本侧登记表**按对象身份认领**（`wpf_pts_loc_find`）⇒ `[LSSESS] rx=OK` 计数 `0→25`；`before` 腿 **0**；**外部反腿**：未登记的身份 ⇒ `feed=-10000 ∧ find=-1` | ✅ **满足**（`win32_pts.c` `WpfLinuxWin32_PtsLsSessFeed` ＋ 生成件 `WpfLinuxLsSessionProbe.Feed`；调用点 `TextParaClient.Linux.cs:111` `ValidateVisual`） |
| **(b) 四格逐条现取** | `Session/Para/InfoPtr/RedefPtr/PtrOk/CbfState/CbfNonzero/CbfMinNonzero/CbfRedefNonzero/CbfLayOk/CbfFp/SrcSlot/ChainSlot/ParaLink/State/Seq` 逐条现取；`mgd` 行 **×25**（互异 `para` 25、互异 `ploc` 3） | ✅ **满足** |
| **(c) 与 `T-A69`／`T-A71` 一一对应** | 段集合**交集 25／25**、只在 `LSSESS` **0**；`src_slot == chain_slot` **25/25**；`link=1` **25/25**；`mism=0` **25/25** | ✅ **满足** |
| **(d) 两极化** | 探针 `SELFTEST mask=0x0f`；反腿副本 `mask=0x03`／`feed=0`／`COUNT=1`／`rc=1`；反极腿 `[LSSESS]` 行 `53→0` | ✅ **满足** |
| **(e) 留痕** | `[LSSESS] rx=OK slot=… seq=… ploc=… para=… info=… redef=… cbf_state=… nonzero=… min_nonzero=…/9 redef_nonzero=… layok=… fp=… src_slot=… chain_slot=… link=… state=BOUND v=LS-SESSION-IN-CHAIN` ×25 ＋ 托管 `[LSSESS] mgd …` ×25 ＋ `[LSSESS] ctx …` ×3 | ✅ **满足** |

### 1.3 🔴 「满足」的**射程**（写死，防读宽）

1. **"会话进链"这一半满足，"排版"那一半不满足**：本趟入站的是**会话身份**（`ploc`，本侧**自持**的真对象）与**段身份**（`nmp`／`_paraHandle`，**宿主**产出）；**回调面指纹**与**两结构指针**是本侧从**该会话对象**上读出的（`T-A68` 的值化副本）。`cLines`／`dcpFirst/dcpLim`／**行盒**一格**未填**（那些还要 `PRECOND-NO-LINE-BREAKER` ＋ 度量源）。
2. **"回调面指纹"是**会话对象上的值拷贝**（写死）**：`fp` ＝ 对 `T-A68` 窗内值化副本（`cbf_info[744]`＋`cbf_redef[24]`）逐字节算的 FNV-1a 64。它**只证**「同一会话的同一面 ⇒ 同值；任一处不同 ⇒ 异值」，**不 deref** 任何槽、**不**主张"该槽可安全调用"。
3. **"两结构指针"的射程（写死）**：`info_ptr`／`redef_ptr` ＝ `LoCreateContext` **两个入参结构**的地址（**原样存、不 deref**）；`PtrOk` 的判据是「**会话句柄仍指回同一个在册对象** ∧ 该对象上的两指针与登记值**逐一相等**」—— 会话被销毁后 `PtrOk` **必回 0**（可证伪），**不**跨销毁缓存 `idx`。
4. **"同一窗内"的语义（写死）**：① `ploc ↔ docCtx` 的配对发生在 `PtsCache.CreatePTSContext`（与 `LoCreateContext` **同一个调用窗**：`textFormatterContext = new TextFormatterContext()` 之后紧接 `PTS.CreateDocContext(…)`，两者之间只有 `GC.SuppressFinalize`）；② `(ploc, para)` 的**对账**发生在托管方法的一次调用窗内（`TextParaClient.ValidateVisual` 内：喂料 ⇒ 立刻回读 ⇒ 逐格对拍）。native 对入参**只存值**（不跨窗持指针）。⚠️ 这**不是** LS 的 `LoCreateLine` 会话窗 —— 那一格仍缺（`PRECOND-NO-LINE-BREAKER`）。
5. **"所属段"可解析的判据有牙（写死）**：`para_link=1` 要求该段身份**同时**在 `T-A69`（内容源）与 `T-A71`（进链）两本台账里解析到；只有一本 ⇒ `state=UNBOUND`（**与"根本没绑定"的 `NONE` 不同形**），**不**用零值／假句柄冒充。

---

## §2 改动（逐处）

### 2.1 native：`src/WpfGfx.Linux.Native/src/win32_pts.c`

1. **新增一段 `T-A72` 块**（`:6056` 起，接在 `T-A71` 块之后）：
   - **常量／结构**：`WPF_PTS_LSS_{MAX=8,ST_NONE/UNBOUND/BOUND,MAGIC="LSSR"}` ＋ `wpf_pts_lssess`（`ploc`／`para`／`info_ptr`／`redef_ptr`／`cbf_state`／`cbf_nonzero`／`cbf_min_nonzero`／`cbf_redef_nonzero`／`cbf_layok`／`cbf_fp`／`src_slot`／`chain_slot`／`para_link`／`state`／`seq`）。
   - **进链（唯一收口）** `WpfLinuxWin32_PtsLsSessFeed(ploc, para)`：先过**四条拒面**（`null-session`／`null-para`／**`not-in-chain`（＝该红必红的牙：`wpf_pts_loc_find` 认不出该会话身份 ⇒ 拒）**／`no-callback-face`（该会话的回调面从未值化 ⇒ 无指纹可给））＋ **`session-conflict`（`C1↔C2` 一一对应：同段被第二个不同会话认领 ⇒ 拒）** ⇒ 拒时**表内不出现该条** ＋ 具名 `[LSSESS] rx=REJECT …out=UNWRITTEN`；收时读该会话的**回调面指纹**（三态／28 槽非零数／最小面 9 槽非零数／`redef` 非零数／布局自证 ＋ FNV-1a 64）与**两结构指针**，按**同一段身份**解析 `T-A69`／`T-A71` 两本台账（`src_slot`／`chain_slot`／`para_link`），打印具名 `rx=OK` 行。
   - **只读回读面**（导出 **26** 名）：`Count`／`Find`／`State`／`Seq`／`Session`／`Para`／`InfoPtr`／`RedefPtr`／`PtrOk`／`CbfState`／`CbfNonzero`／`CbfMinNonzero`／`CbfRedefNonzero`／`CbfLayOk`／`CbfFp`／`SrcSlot`／`ChainSlot`／`ParaLink`／`LiveSessions`／`DistinctSessions`／`Rx`／`RxGap`／`Unbound`／`SelfCheck`／`SelftestMask`／`Feed`。
   - **两极化自检** `…PtsLsSessSelfCheck()`：夹具**会话由 `LoCreateContext` 真造**（⇒ 其 `ploc` 在本侧登记表里**可按对象身份认领**）、**段落由 `T-A69`×`T-A71` 真入站**（子轨对象用 `wpf_pts_sub_new` 真造）；跑 4 位（正极：四格逐格相符 ＋ `para_link=1`／`UNBOUND≠NONE`／反极必拒／**同段冲突必拒 ∧ 原绑定不动**）；收尾**真销毁 ＋ 复原全部可观测状态**（含 `g_pts_loc_*`／`g_pts_lss_*`／`g_pts_pc_*`／`g_pts_textsrc_*`／`g_pts_sub_*`／`g_pts_hc_reading`／`g_pts_lscbf_rx*`／`g_pts_seen[LoCreateContext]`）；表位不足／泄漏 ⇒ `-1`（**不算绿**）。
   - **Fake 路径**：**不在主链**；反腿**只在仓外副本**（`~/tA72-work/replica-native/`，见 §3.4）。

> 🔴 **无假值纪律（四条）**：① 失败路径**一字不写**（表内无该条）；② **会话不入链** ⇒ 诚实拒绝（**不**用"收下即存"冒充"进链"）；③ `UNBOUND`（进链但段无源）与 `NONE`（没绑定）**不同形**；④ 越界 ⇒ **拒**（不截断、不静默）。

### 2.2 生成器：`build/PresentationFramework.Linux/reapply-patches.py`

| 项 | 内容 |
|---|---|
| `LSSESS_PROBE_FILE`／`LSSESS_PROBE_TEXT` | **新建件** `WpfLinuxLsSessionProbe.Linux.cs`：`Enabled`（闸 `WPF_LSSESS_FEED`，**缺省开**、**只有**显式 `"0"` 才关）／`NoteContext(docCtx, ploc)`（`docCtx → ploc` 有界记档 `MaxContexts=256`）／`Feed(docCtx, parah)`（查表得 `ploc`；无 ⇒ 具名 `v=NO-SESSION`；调 native ⇒ **立即回读**并逐格对拍（`Session`／`Para`／`State`／`ParaLink`／`PtrOk`／`CbfState`／`CbfNonzero`／`CbfLayOk`，另印两结构指针与指纹）＋ `npara`／`nsess` ⇒ 一行 `[LSSESS] mgd …`；native 拒绝时单列一行 `v=REJECT-NOT-IN-CHAIN`） |
| `PTSCACHE_E7`（＋4 行） | `TextFormatterContext textFormatterContext;` → `= null;`（**只增初始化**，控制流一字未动） |
| `PTSCACHE_E8`（＋10 行） | 在 `PTS.Validate(PTS.CreateDocContext(…, out context));` 之后加 `WpfLinuxLsSessionProbe.NoteContext(context, (textFormatterContext != null) ? textFormatterContext.Ploc : IntPtr.Zero);` —— **纯增**、不改任何既有控制流 |
| `TPC_E_VV_REPL`（＋4 行） | 在 `TextParaClient` 的 `ValidateVisual` 内（既有 `T-A71` 喂料之后）加 `WpfLinuxLsSessionProbe.Feed(PtsContext.Context, _paraHandle);` —— **纯增**、不改任何既有控制流 |
| `materialize_derived()` | 多写一个**非派生新建件**（`_write_atomic`：`temp + fsync + os.replace`） |
| `PATCH_C` | 多一行 `<Compile Include="…/WpfLinuxLsSessionProbe.Linux.cs" />` |

**幂等（现取）**：连跑两次，全部 `*.Linux.cs` ＋ `csproj` 的合并 `sha16` **两次同值** `d070ac6bd167e7e4` ⇒ `GEN_IDEMPOTENT=YES`。

### 2.3 为什么**必须**落在**托管侧**（不是纯 native）

native **看不到两个身分之一**：`ploc` 是 `TextFormatterContext.Init()`（`upstream/.../TextFormatterContext.cs:113`）在 `PresentationCore` 里拿到的，**只有托管**能读它（`internal IntPtr Ploc`，`TextFormatterContext.cs:483`；`PresentationCore` 对 `PresentationFramework` 开了 `InternalsVisibleTo`，`OtherAssemblyAttrs.cs:11`）；**段身份**（`TextParaClient._paraHandle`）在**宿主**手上。⇒ 只能**由托管发起**；native 侧只做**入站 ＋ 认领校验 ＋ 指纹/指针现取 ＋ 段解析 ＋ 保管 ＋ 回读 ＋ 自检**（**不**自造一格）。

---

## §3 成对读数

### 3.1 三腿（**只差权威 `.so`／`pf` 或一个 env**；同装置 `:231`；证据 `~/tA72-work/legs/`）

| 腿 | 权威 | env | 证据目录 | `LEGS_RUNNER` |
|---|---|---|---|---|
| `before` | `.so 53116d7456f62c44`／`pf 7cfcfa8c1f024b35`（改前） | — | `~/tA72-work/legs/before/` | `PASS requested=2 obtained=2 refused=0` |
| `after` | `.so 630cefb6c7bdf0f0`／`pf 94a73efe3bc68808`（改后） | — | `~/tA72-work/legs/after/` | `PASS requested=2 obtained=2 refused=0` |
| `rev`（**反极腿**） | 同 `after` | `WPF_LSSESS_FEED=0` | `~/tA72-work/legs/rev/` | `PASS requested=2 obtained=2 refused=0` |

同批工具（现取）：`runner_sha16=330a90f1f0ac28e4`／`session_sha16=f1a582d9ea9788c9`／`guard_sha16=ead59d60ccfc95b0`／`legs-to-env.py=ed290f41e5ae6432`；`device.txt`：`X_UP=yes display=:231`。

### 3.2 靶面成对（`grep -c` 现取，`app_g1.log`）

| 量 | `before`（改前） | `after`（改后／缺省） | `rev`（`FEED=0`） |
|---|---|---|---|
| `[LSSESS] ctx`（`NoteContext` 行） | **0**（旧件无此面） | **3** | **0** |
| `[LSSESS] mgd`（托管对拍行） | **0** | **25** | **0** |
| `… mgd … state=2`（BOUND） | — | **25/25** | — |
| `… mgd … link=1`（与两本台账一一对应） | — | **25/25** | — |
| `… mgd … ptr=1`（两结构指针一致性） | — | **25/25** | — |
| `… mgd … mism=0` | — | **25/25** | — |
| `… mgd … v=NO-SESSION` | — | **0** | — |
| `… mgd … v=REJECT-NOT-IN-CHAIN` | — | **0** | — |
| `[LSSESS] rx=OK`（native 进链行） | **0**（旧件无此面） | **25** | **0** |
| `[LSSESS] rx=REJECT` | **0** | **0** | **0** |
| 互异 `ploc`（`[LSSESS]` 行内） | — | **3** | — |
| 互异 `para`（`[LSSESS]` 行内） | — | **25** | — |
| `[LSSESS]` 行总数 | 0 | **53** | **0** |
| `[HC-UNHANDLED]` ／ `entry point named` ／ `failfast+unrec` | 0 ／ 0 ／ 0 | 0 ／ 0 ／ 0 | 0 ／ 0 ／ 0 |

**逐条四格现取（样例，逐字）**：

```
[LSSESS] ctx doc=0x584fdd4dcd20 ploc=0x584fe303b840 live=1 v=LS-SESSION-NOTED
[LSSESS] ctx doc=0x584fdd525cf0 ploc=0x584fe239efb0 live=2 v=LS-SESSION-NOTED
[LSSESS] ctx doc=0x584fdc7d6fd0 ploc=0x584fdd51e4f0 live=3 v=LS-SESSION-NOTED
```

```
[LSSESS] mgd ploc=0x584fe303b840 para=0x584fe3040f44 rc=0 slot=0 info=0x7ffd7f1d1e38 redef=0x7ffd7f1d1e00 cbf_state=2 nonzero=26 min=8/9 redef_nz=3 layok=1 fp=2314400fd74c521e ptr=1 src_slot=0 chain_slot=0 link=1 state=2 npara=1 nsess=1 mism=0 v=LS-SESSION-IN-CHAIN
[LSSESS] mgd ploc=0x584fdd51e4f0 para=0x584fdc7d7634 rc=0 slot=0 info=0x7ffd7f1d7658 redef=0x7ffd7f1d7620 cbf_state=2 nonzero=26 min=8/9 redef_nz=3 layok=1 fp=22c47f32cca999aa ptr=1 src_slot=0 chain_slot=0 link=1 state=2 npara=8 nsess=2 mism=0 v=LS-SESSION-IN-CHAIN
```

```
[LSSESS] rx=OK slot=0 seq=1 ploc=0x584fe303b840 para=0x584fe3040f44 info=0x7ffd7f1d1e38 redef=0x7ffd7f1d1e00 cbf_state=2 nonzero=26 min_nonzero=8/9 redef_nonzero=3 layok=1 fp=2314400fd74c521e src_slot=0 chain_slot=0 link=1 state=BOUND v=LS-SESSION-IN-CHAIN
```

**段↔会话分布（现取，逐行 `ploc` 计数）**：`0x584fe303b840` **12** 段／`0x584fe239efb0` **12** 段／`0x584fdd51e4f0` **1** 段；**回调面指纹**逐会话各一枚（`2314400fd74c521e`／`41d93354fc6a22f4`／`22c47f32cca999aa`）。

**与 `T-A69`／`T-A71` 一一对应**现取（逐段对拍，脚本 `python3` 现跑）：
```
LSSESS para: 25   TEXTSRC para: 25   PARACHAIN para: 25
交集 L∩T: 25   L∩P: 25   只在L: 0   只在T: 0   只在P: 0
src_slot == chain_slot: 全 25 行成立；link=1 全 25 行；mism=0 全 25 行
```

### 3.3 探针（`dlopen` 直调；正极 ＝ 主链 `.so`）

> ⚠️ **口径（写死）**：本条的**正极**（"在册会话 ＋ 可解析段"）**只能由 native 侧造**（"在册会话"＝ `LoCreateContext` 的产物、子轨对象＝ `wpf_pts_sub_new` 的产物，探针无此导出）⇒ 正极由**自检**在 native 内用夹具完成；探针在外部做**负面面**（**会话不入链 ⇒ 必拒**）与**越界哨兵**。

```
EXPORTS present=26/26
== selftest ==
SELFTEST mask=0x0f rc=4/4
SELFTEST2 mask=0x0f（幂等：自检不改变可观测状态）
== negative (session NOT in chain) ==
NOCHAIN feed(local)=-10000 feed(0x5a5a5a5a)=-10000 find(local)=-1 find(0x5a5a5a5a)=-1
== bad args ==
FEED(null,null)=-10000 FEED(local,null)=-10000 FEED(null,local)=-10000
OOB state=-1 sess=(nil) para=(nil) info=(nil) ptrok=-1 cbfstate=-1 cbfnz=-1 cbfmnz=-1 layok=-1 srcslot=-2 chain=-2 link=-1
== counters ==
COUNT=0 DISTINCT=0 LIVE=0 RX=0 RXGAP=10 UNBOUND=0
PROBE selftest_mask=0x0f nochain_rejected=1 badargs_rejected=1 nosession_find=-1 rc=0   （MAIN_RC=0）
```

### 3.4 🔴 **反腿副本**（`not-in-chain` **只记不拒**＝静默半通；该红必红）

`~/tA72-work/replica-native/bin/libwpfwin32.so` ＝ **`73096e93a832cf90`**（仓外副本：把进链收口的 `not-in-chain` 闸由"`if (!c) 拒`"改成"`if (!c) c = &g_pts_lss_phantom;`"（＝"**会话不在链上也收下**"的静默半通形态；**主链一字未含该路径**）。

```
SELFTEST mask=0x03 rc=PARTIAL
NOCHAIN feed(local)=0 feed(0x5a5a5a5a)=0 find(local)=-1 find(0x5a5a5a5a)=-1
PROBE selftest_mask=0x03 nochain_rejected=0 badargs_rejected=1 nosession_find=0 rc=1   （REPLICA_PROBE_RC=1）
COUNT=1 DISTINCT=1 LIVE=0 RX=3 RXGAP=6 UNBOUND=3
```

⇒ **该红必红（两条独立证据）**：① **自检位** `0x0f→0x03`（**bit2「反极必拒」当场灭** ＋ **bit3「同段冲突必拒」因表被污染而连锁灭**）；② **探针反腿**：`feed(local)` 由 `-10000` 变 **`0`**（"**会话不在链上的身份也被收下**"）且 `COUNT` 由 `0` 变 **`1`**（**表被静默污染**）。⇒ 本条的"**会话进链**"**不是恒真断言**（它能把"没验会话就收下"照出来）。

### 3.5 反极腿（`WPF_LSSESS_FEED=0`；同一权威件）

| 量 | `after`（缺省） | `rev`（`=0`） |
|---|---|---|
| `[LSSESS]` 行总数 | **53**（3 `ctx` ＋ 25 native ＋ 25 mgd） | **0** |
| 本趟自定判据 `LSSESS_GUARD`（＝`mgd>0 ∧ 全部 rc=0 ∧ 全部 state=2 ∧ 全部 ptr=1 ∧ 全部 link=1 ∧ 全部 mism=0`；命令见 §4） | **PASS** | **FAIL**（无正读数 ⇒ 红） |
| `PTS_GUARD`／`PTS_COLORANCHOR`／`PTS_ENFE`／症状门 | `PASS legs=2/2`／`PASS hits=3`／`PASS total=0`／逐格 | **同**（如实记：本通道**观测用、不承重像素** ⇒ 这三门**不因它翻红**） |

> ⚠️ **如实披露（防读宽）**：本通道**不改变渲染**，所以反极腿的 `PTS_GUARD`／`PTS_COLORANCHOR` **两腿同值**（`colors 1220/636`、色锚不变）⇒ "无进链 ⇒ 该红必红"**由本趟自定判据 ＋ §3.4 副本承担**，**不**由页门承担（页门在这条面**结构性不可分**）。

### 3.6 症状门 ＋ 帧面成对

| 量 | `before` | `after` | `rev` |
|---|---|---|---|
| `k24` | `alive=yes app_rc=143 magenta=0 colors=1220 ae=220019 ink=480000 failfast=0 unrec=0` | **同** | **同** |
| `k23` | `alive=yes app_rc=143 magenta=0 colors=636 ae=136292 ink=480000 failfast=0 unrec=0` | **同** | **同** |
| `PTS_GUARD` | `PASS legs=2/2` | **`PASS legs=2/2`** | **`PASS legs=2/2`** |
| `PTS_COLORANCHOR`（k24） | `PASS hits=3` | **`PASS hits=3`**（`GhostWhite=9794 Beige=910 DarkGreen=44 LightGoldenrodYellow=5830`） | **同** |
| `PTS_ENFE` | `PASS total=0` | `PASS total=0` | `PASS total=0` |

| 对 | `boot` | `k23` | `k24` | `last` |
|---|---|---|---|---|
| `fr_sha(before)` | `b21eb530afd3c66c` | `10d0b9d54e649c10` | `0bdb2dfd05952bc9` | `10d0b9d54e649c10` |
| `fr_sha(after)` | `b21eb530afd3c66c` | `10d0b9d54e649c10` | `0bdb2dfd05952bc9` | `10d0b9d54e649c10` |
| `fr_sha(rev)` | `b21eb530afd3c66c` | `10d0b9d54e649c10` | `0bdb2dfd05952bc9` | `10d0b9d54e649c10` |
| `AE(before,after)`／`AE(after,rev)` | **0／0** | **0／0** | **0／0** | **0／0** |

⇒ **零回归**（逐字节相同）。

---

## §4 门禁（现取；`rc` 一律取自 `>out 2>err; echo $?` 形态）

| 门 | 读数 | rc |
|---|---|---|
| `nm==exports` | `nm -D --defined-only` ＝ **824** ＝ `exports.txt` 行数；**逐名 `diff` 零差异**；**新增 26 名、无消失**（`WpfLinuxWin32_PtsLsSess{Feed,Count,Find,State,Seq,Session,Para,InfoPtr,RedefPtr,PtrOk,CbfState,CbfNonzero,CbfMinNonzero,CbfRedefNonzero,CbfLayOk,CbfFp,SrcSlot,ChainSlot,ParaLink,LiveSessions,DistinctSessions,Rx,RxGap,Unbound,SelfCheck,SelftestMask}`） | 0 |
| `PTSGAP` | `PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=630cefb6c7bdf0f0 exports=824`（`tool/ops/impl` **未动**；`PTSGAP_HISTORICAL=n=11`；`PTSGAP_CITED=PASS refs=1`；`PTSGAP_FRONTIER_STATE=NAMED frontier=FsQueryTextDetails`） | 0 |
| `DEFREG` | `PASS declared=225 route_ids=225`；`DECLDRIFT=0 keys=-` | 0 |
| `REPORTID` | `PASS files=347 ids=2257 declared=225`（本件落盘前 `346` ⇒ 落盘后 `347`，`+1` 即本件） | 0 |
| `HANDOFF_MV` | `PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none`（已按第 `28` 条契约在 `HANDOFF-NEXT.md` 文件尾**只增**追写机器值契约行，`inputs_fp eefad720…→66a10171…`） | 0 |
| `GEN_IDEMPOTENT` | 连跑两次：全部 `*.Linux.cs` ＋ `csproj` 的合并 `sha16` ＝ `d070ac6bd167e7e4`（两次同值） | 0 |
| `PTS-PAGES`（腿产证据） | `PTS_GUARD=PASS legs=2/2`／`PTS_COLORANCHOR=PASS k=24 hits=3`／`PTS_ENFE=PASS total=0`（三条腿各一次，逐腿同值） | 0（判据 `--legs` 纯读） |
| **本趟自定判据** `LSSESS_GUARD` | `mgd>0 ∧ 全部 rc=0 ∧ 全部 state=2 ∧ 全部 ptr=1 ∧ 全部 link=1 ∧ 全部 mism=0`（命令：`grep -a '\[LSSESS\] mgd' <leg>/app_g1.log` 取计数）；`after` ⇒ **PASS**（25/25/25/25/25/25）；`rev` ⇒ **FAIL**（0 条正读数） | 0／1 |

---

## §5 逐件 `sha16`（现取）

| 件 | 改前 | 改后 |
|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `6ad1500b59cd7cf0`（790224 B／10710 行） | **`ab4b685704b53ed3`**（817199 B／11087 行） |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so`（**非仓内件**） | `53116d7456f62c44`（533832 B） | **`630cefb6c7bdf0f0`**（544008 B） |
| `src/WpfGfx.Linux.Native/bin/exports.txt`（**非仓内件**） | `3fc15b59b35739f3`（798 行） | **`e5675ec32f7323df`**（824 行） |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `a9eb06731f1f3b42`（649 行） | **`9a2212296af5ea24`**（674 行） |
| `build/PresentationFramework.Linux/reapply-patches.py`（生成器） | `0fdbadc739470b47`（172833 B） | **`80c84ee298ca1b6d`**（187697 B） |
| `…/PtsCache.Linux.cs`（重产件） | `e5b399fdb8742092`（1658 行） | **`3297abe6ad00d4ad`**（1671 行；＋13 行：`= null;` ＋ `NoteContext` 调用 ＋ 注释） |
| `…/TextParaClient.Linux.cs`（重产件） | `b88451d6edaa28d0`（4329 行） | **`ac37879992d9572f`**（4333 行；＋4 行：喂料调用 ＋ 注释） |
| `…/PresentationFramework.Linux.csproj`（重产件） | `f19cfdaeebce4892` | **`74f7401735efe70b`**（＋2 行：新件 `<Compile Include>`） |
| `…/WpfLinuxLsSessionProbe.Linux.cs`（重产件 · **本趟新建**） | — | **`47207a1a5a616fca`**（10473 B／173 行） |
| `build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll`（**非仓内件**） | `7cfcfa8c1f024b35`（6152704 B） | **`94a73efe3bc68808`**（6156800 B） |
| `docs/ROUTES.md` | `9e126bd9443c8c65`（1132 行） | **`4e0239f346632268`**（1133 行） |
| `build/MilBridge/HANDOFF-NEXT.md` | `79cdfa566464cff9`（771 行） | **`a8f415ea3adbaef4`**（773 行；文件尾**只增**两段机器值契约行） |
| `docs/WAVE66-PREREGISTRATION.md`（**冻证据**） | `bf6b683d94549087` | **未变**（`bf6b683d94549087`） |

> ⚠️ 生成器**重产件**里 `ContainerParaClient.Linux.cs`／`FlowDocumentView.Linux.cs`／`FlowDocumentPage.Linux.cs`／`PtsPage.Linux.cs`／`PtsHelper.Linux.cs`／`FigureParaClient.Linux.cs`／`FlowDocumentFormatter.Linux.cs`／`FlowDocumentPaginator.Linux.cs`／`WpfLinuxChainProbe.Linux.cs`／`WpfLinuxTextSrcProbe.Linux.cs`／`WpfLinuxCpDcpMapProbe.Linux.cs`／`WpfLinuxTextParaChainProbe.Linux.cs`／`DeferredTextReference.Linux.cs`／`FrameworkElement.Linux.cs`／`SystemResources.Linux.cs`／`TextBlock.Linux.cs`／`TextBoxBase.Linux.cs`／`TextBox.Linux.cs`／`TextContainer.Linux.cs`／`TextEditorTyping.Linux.cs`／`Window.Linux.cs` **逐字节未变**（现取 22 件里 19 件未变，3 件为上方具名者）。

---

## §6 诚实边界（**防读宽**，逐条）／具名 `NOINFO`

1. 🔴 **本条只判"会话身份在链上可认领 ∧ 所属段在两本台账里可解析 ∧ 回调面指纹与两结构指针可逐格现取 ∧ 可两极化"**；**不**判"排版前进"、**不**判"`W` 解除"（三腿四帧逐字节同 ⇒ **零像素位移**）。
2. 🔴 **"进链"不是"本侧是作者"**：`ploc` 由**托管**（`LoCreateContext`）产出、段身份由**宿主**产出；native **只收／只认领／只现取／只解析／只回读**（`P1-layout-content-criteria.md:146` 的 `P9` 边界仍成立）。
3. 🔴 **"回调面指纹"的射程**：它是**该会话对象上 `T-A68` 值化副本**的 FNV-1a 64 ＋ 四项计数——**只证**「面值一致/不一致」，**不 deref** 任何槽、**不**主张"该槽可安全调用"、**不**主张"LS 引擎在跑"。
4. 🔴 **"两结构指针"的射程**：`info_ptr`／`redef_ptr` 是**托管入参结构地址**（封送期有效 ⇒ 本侧**只存值、不 deref**；§3.1 的 `info=0x7ffd…` 是**栈地址**、跨调用**不具身份**）；`PtrOk` 的牙在"**会话句柄仍指回同一个在册对象** ∧ 该对象上的两指针与登记值逐一相等"。
5. 🔴 **"一一对应"的射程**：`para_link` **只接**「同段身份 ⇒ `T-A69` 表 ∧ `T-A71` 表**同时**可解析」这一件事；它**不**主张"该字符序列与某行/某盒对应"（那是排版面）。
6. 🔴 **"进链 ≠ 排版"**：本块**不**填任何几何／行盒／`cLines`／`dcp` 区间；`PRECOND-NO-LINE-BREAKER`／`C2` 的 `plsrun` 那一半**仍在册**；`FullText` 只在 LS 造型窗内非空（`LineServicesCallbacks.cs:3448`），而本移植**绕过 LS 造型**（`build/PresentationCore.Linux/TextFormatterImp.Linux.cs`）⇒ 该格**结构性不可达**（**不冒充**）。
7. 🔴 **"同一窗内"的精确射程（防读宽）**：`ploc ↔ docCtx` 的配对发生在 `CreatePTSContext`（与 `LoCreateContext` 同一调用窗），`(ploc, para)` 的对账发生在 `ValidateVisual` 窗；**两者是同一个"托管窗"族、不是 LS 的 `LoCreateLine` 会话窗** —— 后者由 `PRECOND-NO-LINE-BREAKER` 的下一格承担。
8. 🔴 **`PTS_GUARD`／`PTS_COLORANCHOR`／`PTS_ENFE` 在本条面上不可分**：本通道**观测用**、**不承重像素** ⇒ 反极腿这三门**同值**；"无进链 ⇒ 该红必红"由**自定判据 ＋ §3.4 副本**承担。
9. 🔴 **有界性（如实记）**：在册条数 ≤ `8`；**表满 ⇒ 有界复用最旧槽**（具名行带 `slot=`）。本趟 25 段**落在 8 槽上轮转**（`npara` 由 `1…8` 后**封顶 8**）⇒ 回读面是"**最近 8 条**"视图，**不是**全量台账（**明示，防读成全量**）；§0-2 的"会话数 3／段数 25"是**逐行现取后再归并**（每行自带 `ploc`／`para`），**不是**台账容量。
10. **具名 `NOINFO`（逐条给"消掉条件"）**：
    - **`NOINFO-LSSESS-LS-ENGINE-RUNNING`**：本侧**只证**"`LoCreateContext` 被调过 ∧ 其产物可认领 ∧ 面可现取"；"LS 引擎**真在跑**（`LoCreateLine`／`LoCreateBreaks` 被驱动）"**仓内无读数**。**消掉条件**：`PRECOND-NO-LINE-BREAKER` 落地并出现 `LoCreateLine` 真读数。
    - **`NOINFO-LSSESS-SESSION-SERVES-PARA`**：本侧**不**主张"该会话**真被用于**排该段"（本移植绕过 LS 造型 ⇒ 无该因果面）。**消掉条件**：LS 造型链真跑起来（同上）。
    - **`NOINFO-LSSESS-CROSS-PAGE`**：粒度 ＝ **单段落**（承契约 `:100`）；"跨页/整页"结论**不由本条宣布**。
    - **`NOINFO-LSSESS-DOCCTX-IDENTITY`**：`docCtx → ploc` 的记档是**托管侧**有界表（`MaxContexts=256`，超出即重开表）—— 本侧**不**主张"native 侧有可认领的**页/子页**对象与该会话同窗绑上"。**消掉条件**：native 侧有可认领的页/子页对象（承 `PRECOND-LS-SESSION-DRIVER` 的下一格）。
11. **未跑整趟 `verify-all`**（照派单）；本节所有"不得读成绿"的口径照在册红榜 `P1–P10`。

---

## §7 遗留（下一增量具名靶）

- **`W` 余项**：`PRECOND-NO-LINE-BREAKER` ／ `C2` 的 `plsrun` 那一半**未解除**（`PRECOND-LS-SESSION-DRIVER` 的**字面**已由本条推进为"**有可现取的真读数**"：会话身份可认领 ∧ 回调面指纹可现取 ∧ 两结构指针一致性有牙）；本件**不**授权任何判据放宽。
- **最近的一格（可选）**：把"**最近 8 条**"的有界视图升为"按证据序号可追"（例如每条一条 `ev_seq`；今天 `npara` 封顶 8）。
- **越级项（须队长裁定）**：`PRECOND-NO-LINE-BREAKER`（行断器）＋ 度量源（`LS-CB-M1` 的 `GetRunTextMetrics`／`GetRunCharWidths`）—— 二者是判据 `:100` 的六条合取之 ④（行盒）的真前置；本条**未**触碰。
- **契约 `C2` 的另一半**：`plsrun`（由 `LineServicesCallbacks` 分配）**仍不在链上**；契约 §5 反腿 (b)（跨段复用同一 `plsrun` 表）**本趟不可跑**（无 `plsrun` 面）⇒ 本条把它的**同形**牙（`session-conflict`）落在**会话↔段落**这一层，**不冒充** `plsrun` 面。
`P1-TAIL2-LSSESSION 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 7c46cf9154813539（末行＝本行）`

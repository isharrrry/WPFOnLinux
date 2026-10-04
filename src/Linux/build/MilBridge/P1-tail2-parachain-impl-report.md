# `P1-tail2` · `T-A71` · **文本段落进链（`PRECOND-NO-TEXT-PARA-IN-CHAIN`；`W` 合取④）**（`TASK-0307` 增量）—— 实现报告

**判决**：把在册前置 `PRECOND-NO-TEXT-PARA-IN-CHAIN`（`build/MilBridge/P1-layout-content-criteria.md:114`：「现链上是容器段落，`TextParaClient` 是**另一族**」；`P1-tail2-dingrecon.md` §3.2 列为 `W` 合取**第四条**）落地成 native 侧一条**进链台账（按段身份可寻址）＋ 逐段只读回读面 ＋ 两极化自检**：**托管侧**（生成器重产件 `WpfLinuxTextParaChainProbe.Linux.cs` ＋ `TextParaClient.Linux.cs` 一处调用）在**同一次调用窗内**把**文本段落的链坐标**交给 native —— **段身份**（`_paraHandle`）／**所属页**（`_pageContext` 的同一性序号，同页同号）／**`cp` 域**（`[ParagraphStartCharacterPosition, +text.Length)`，宿主真值）；native **当场按对象身份认领**（`wpf_pts_sub_claim`）并在认领到的**子轨对象**上读 **`sub_seq`**，再把**内容源句柄**按**同一段身份**接到 `T-A69` 的内容源表（⇒ **一一对应**，`LinkOk` 为其机器读数），随后托管**回读并逐格对拍**。**真腿现取（`after`）**：`[PARACHAIN] mgd … rc=0 slot=… state=2 sub=1 src_slot=… link=1 mism=0 v=TEXT-PARA-IN-CHAIN` **×25** ＋ native `[PARACHAIN] rx=OK …` **×25**（`distinct_parah=25`／`distinct_page=21`／`rx_reject=0`）。**两极化**：探针 `[PARACHAIN-SELFTEST] mask=0x0f`（4/4）；外部反腿 `NOCHAIN feed=-10000 find=-1`；**反腿副本**（认领**只记不拒**＝静默半通）⇒ `mask=0x07`、`feed=0 find=-1`、`PROBE_RC=1`（**该红必红**）；**反极腿**（`WPF_PARACHAIN_FEED=0`）⇒ 本侧 `[PARACHAIN]` 行 **0 条**。**零回归**（改前/改后/反极三腿四帧**逐字节同**；`PTS_GUARD=PASS`／`PTS_COLORANCHOR=PASS hits=3`）。**导出面**：`exports 778→798`（逐名 **+20**、**无消失**），`nm==exports`；`PTSGAP`／`DEFREG`／`REPORTID`／`HANDOFF_MV` rc=0。🔴 **如实划界（本件的核心判决）**：**进链 ≠ 排版** —— 本条**只**判「文本段落**在链上可寻址** ∧ 五格（段身份／页／子轨／`cp` 域／源句柄）**逐段现取** ∧ 与 `T-A69` **一一对应** ∧ 可两极化」；它**不**填任何几何／行盒／`cLines`／`dcp` 区间；`PRECOND-NO-LINE-BREAKER`／`PRECOND-LS-SESSION-DRIVER`／`C2` 的 `plsrun` 那一半**仍在册** ⇒ `W` 整体**未解除**。

- **读时**：`2026-10-01T23:4x–2026-10-02T00:0x+0800`（本席现取；各条另注）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`（**未 `git add/commit/push`**）；开工 `HEAD=6c95cf4`（`T-A69`）；⚠️ **开工时工作树已带 `T-A70`（契约 `C4`）的未提交改动**（`git status` 现取：`M src/WpfGfx.Linux.Native/src/win32_pts.c`／`M …/pts-gap-decl.txt`／`M …/reapply-patches.py`／`M …/TextParaClient.Linux.cs`／`M …/PresentationFramework.Linux.csproj`／`M docs/ROUTES.md`／`M build/MilBridge/HANDOFF-NEXT.md`／`?? build/PresentationFramework.Linux/WpfLinuxCpDcpMapProbe.Linux.cs`／`?? build/MilBridge/P1-tail2-c4-impl-report.md`）—— **本件在那一份之上叠加**（照"本轮唯一写者"的口径，**不撤回**他件改动）。
- **改前件备份（仓外 `~/tA71-work/bak/`，`cp -p`，取在**任何写之前**）**：`win32_pts.c`（`4ec3e0dfe2950b06`／769019 B）／`bin/libwpfwin32.so`（`c5acc47490098ff0`／524008 B）／`bin/exports.txt`（`92c091935f07df42`／778 行）／`tools/pts-gap-decl.txt`（`8f7099defa925673`／629 行）／`build/PresentationFramework.Linux/reapply-patches.py`（`12b69807e6846637`／160656 B）／其重产件（`bak/generated/` 全套）／`PresentationFramework.dll`（`75f1a79441d01b16`）／`docs/ROUTES.md`（`57a77e0df44834a6`／1131 行）／`build/MilBridge/HANDOFF-NEXT.md`。
- **写域（逐件）**：`src/WpfGfx.Linux.Native/src/win32_pts.c`（**加一段 `T-A71` 块**：进链台账 ＋ 只读回读面 ＋ 两极化自检；**并在 `T-A69` 块加一个内容源句柄访问器** `WpfLinuxWin32_PtsTextSrcHandle`）／`src/WpfGfx.Linux.Native/bin/exports.txt`（**构建重产**，非手改）／`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（DECL 行 `so16`／`exports` 跟权威件换 ＋ 只增一段 `T-A71` 重锚）／**生成器** `build/PresentationFramework.Linux/reapply-patches.py`（新增 `PARACHAIN_PROBE_FILE`／`PARACHAIN_PROBE_TEXT` ＋ `TPC_E_VV_REPL` 一处调用 ＋ `materialize_derived()` 写新件 ＋ `PATCH_C` 一行 `<Compile Include>`）／**其重产件**（`WpfLinuxTextParaChainProbe.Linux.cs` **新建件**、`TextParaClient.Linux.cs`、`PresentationFramework.Linux.csproj`）／**复述位现值位**（`docs/ROUTES.md` `TASK-0307` 行加一条 dated 结账；`build/MilBridge/HANDOFF-NEXT.md` 文件尾机器值契约追写）／**新建载体** 本件。
- **未改**（如实体例）：`docs/WAVE66-PREREGISTRATION.md`（冻证据 `w66pre16=bf6b683d94549087` 未动）；`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`src/WpfGfx.Linux.Native/src/win32_classification.c`（本趟**未移动**它们所持的 `tool/ops/impl` 三格 ⇒ `PTSGAP` 判据**要求**它们**不动**，见 §4）；`bin/libwpfwin32.so`／`bin/exports.txt`／`build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` 属**构建产物**（非仓内件）。
- **黑名单遵守**：未动 `build/MilBridge/tools/**`（**只读跑**判据件）／`verify-all.sh`／`build/close-wave.sh`／`build/shims/**`／`upstream/**`（只读）；**未跑**整趟 `verify-all`；未改相位位；未 `git add/commit/push`。⚠️ 如实记：`build/MilBridge/tools/defect-registry-declared.tsv` 在 `git status` 里呈 `M`（**只差一行 `DECL-GEN` 时间戳**）—— 那是**跑判据件自身**的副产（`--emit`），**本席未手改其内容**（该 `M` 在本件开工前即已存在）。
- **重活**：**2 趟 native 构建**（主链 `--symbols` ＋ 仓外反腿副本）＋ **1 趟托管构建**（`0 警告 0 错误`，`20.3 s`）＋ **1 趟跑器**（`before`／`after`／`rev`，共 **6 条腿**），全走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- <cmd>`（逐趟 `HEAVYSLOT=ACQUIRED/MEMOK/RELEASED rc=0`）；进程只按 PID；显示位只用跑器自分配的号（`DISPLAY_PICK :231`）；禁 `sleep` 轮询；写前 `cp -p`；`temp+rename`（生成器 `_write_atomic`；本席改文档亦走 `tmp+os.replace`）；模式守恒。
- **口径**：一切读数**本席现取**（`sha256sum`／`nm -D --defined-only`／`diff`／`grep -c`／`gcc` 编译的 `dlopen` 探针 `~/tA71-work/probe`／只读跑 `bash build/MilBridge/tools/{pts-gap-count-check,pts-pages-guard,defect-registry-check,report-id-domain-check,handoff-machine-values-check}.sh`）。凡引他件处一并标注。

---

## §0 结论速览（自包含）

1. ✅ **「文本段落进链」= 真进链（现取）**：`after` 腿 `app_g1.log` 里 `[PARACHAIN] rx=OK … v=TEXT-PARA-IN-CHAIN` **25 条** ⇒ 托管在真应用里把**25 个文本段落**的链坐标交进 native 且**逐个按对象身份认领成功**；`before` 腿 **0 条**（旧件无此面）。
2. ✅ **逐段五格可现取**：`[PARACHAIN] mgd … page=… cp=[…,…) n=… state=2 sub=1 src_slot=… link=1 mism=0` **×25**（`cch ∈ {9,12,13,16,22,38,40,568,588,882}`；`distinct_parah=25`；`distinct_page=21`）＋ native `rx=OK … sub_seq=…` ×25（`sub_seq` 25 个**互异**值 ⇒ 认领到的是**各自**的本侧子轨对象）。
3. ✅ **与 `T-A69` 内容源一一对应（现取，逐段对拍）**：同一批 25 段，`src_slot == PtsTextSrcFind(parah)` ∧ `cp`／`cch` 与 `[TEXTSRC] mgd` 行**逐段相符** ⇒ **失配 0**（集合：交集 25／只在 `TEXTSRC` 0／只在 `PARACHAIN` 0）；native `LinkOk(k)==1` **25/25**。
4. ✅ **两极化（该红必红）**：① 探针 `[PARACHAIN-SELFTEST] mask=0x0f`（4/4：链上段∧有源／`UNSOURCED≠NONE`／反极必拒／**不在链上必拒**）；② **反腿副本**（`~/tA71-work/replica.so 15b861d530151d3f`，认领**只记不拒**）⇒ `mask=0x07`（bit3 灭）＋ 外部反腿 `NOCHAIN feed=0 find=-1` ＋ `PROBE_RC=1` ⇒ **该红必红**；③ **反极腿**（`WPF_PARACHAIN_FEED=0`，同一权威件）⇒ `[PARACHAIN]` 行 **0 条**。
5. ✅ **零回归**：`.so c5acc47490098ff0（改前）→ 53116d7456f62c44（改后）`／`pf 75f1a79441d01b16 → 7cfcfa8c1f024b35`；三腿（`before`／`after`／`rev`）四帧**逐字节相同**（`AE=0`；`boot b21eb530afd3c66c`／`k23 10d0b9d54e649c10`／`k24 0bdb2dfd05952bc9`／`last 10d0b9d54e649c10`）、症状门逐格同；`PTS_GUARD=PASS legs=2/2`／`PTS_COLORANCHOR=PASS k=24 hits=3` **未回退**。
6. ✅ **门禁四件（现取）**：`nm -D --defined-only` ＝ `exports.txt` ＝ **798**（逐名 `diff` 零差异；**+20 无消失**）；`PTSGAP=PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=53116d7456f62c44 exports=798`（rc=0）；`DEFREG=PASS declared=225 route_ids=225`（rc=0，`DECLDRIFT=0`）；`REPORTID=PASS files=346 ids=2257 declared=225`（rc=0）；`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0`（rc=0）。
7. 🔴 **如实划界（本件的核心判决）**：本条**只**判「**文本段落在本侧链上可寻址 ∧ 五格逐段现取 ∧ 与 `T-A69` 一一对应 ∧ 可两极化**」。它**不**判「排版前进」、**不**判「`W` 解除」—— `PRECOND-NO-LINE-BREAKER`／`PRECOND-LS-SESSION-DRIVER`／`C2`（`plsrun` 那一半）**仍在册**；「**进链**」与「**排版**」是两件事（三腿四帧逐字节同 ⇒ **零像素位移**）。

---

## §1 「文本段落进链」的**准入判据**（现取：件:行 ＋ 满足／不满足）

> **判据一律逐字引自**已登载的判据件（件:行）；行号只保证本次有效（内容锚原文一并给）。

### 1.1 在册出处（逐字）

| 角色 | 件:行 | 现取原文（要点） |
|---|---|---|
| **前置本体（本条的靶）** | `build/MilBridge/P1-layout-content-criteria.md:114` | 「**`PRECOND-NO-TEXT-PARA-IN-CHAIN`**：现链上是容器段落，`TextParaClient` 是**另一族**。」 |
| **`W` 合取④** | `build/MilBridge/P1-tail2-dingrecon.md:94`（§3.2） | 「**文本段落进链** —— `PRECOND-NO-TEXT-PARA-IN-CHAIN`（同上 `:114`）。」 |
| **§3.2 第 1 条（同族）** | `P1-tail2-dingrecon.md:91` | 「**LS 会话进链**：`LoCreateContext` 的 `ploc` 与文本段落 `nmp` 在本侧同一窗内可观测」 |
| **准入的形式条件** | `P1-tail2-dingrecon.md:98` | 「**当且仅当** `W` 每项在同一趟腿上有**可现取的真读数／具名留痕**（`P10`）时，"内容层那一波"＝**已落地**。」 |
| **判据 `:100` 前置之 (iii)** | `P1-layout-content-criteria.md:102` | 「**前置（三条，缺一不可）**：…**(iii)** 链上真的出现**文本段落**。」 |
| **源在谁手上（`P9` 边界）** | `P1-layout-content-criteria.md:146` | 「**源在宿主侧**（托管 `TextContainer`/`TextFormatter`……）……本件只判"**取它要开新面**"」 |
| **粒度（承契约）** | `build/MilBridge/P1-ls-provenance-contract.md:100` | 「粒度：**单段落**」（本件不宣布跨页/整页结论） |

⇒ **本条把"文本段落进链"判据化（写死）为五条合取**：**(a) 台账可寻址**（按**段身份**查得；段身份**必须是本侧链上对象**才收，否则诚实拒绝）；**(b) 五格逐段现取**（**段身份／所属页／子轨／`cp` 域／内容源句柄**）；**(c) 与 `T-A69` 内容源一一对应**（同段身份 ⇒ 同源表项，且**逐段**相符）；**(d) 两极化**（**不在链上 ⇒ 必拒**；`WPF_PARACHAIN_FEED=0` ⇒ 0 条）；**(e) 留痕**（`[PARACHAIN]` 具名行）。

### 1.2 逐条现取（满足／不满足）

| # | 判据 | 现取读数（`after` 腿／探针） | 判定 |
|---|---|---|---|
| **(a) 可寻址＋进链有牙** | 段身份必须能在本侧台账**按对象身份认领**（`wpf_pts_sub_claim`）⇒ `[PARACHAIN] rx=OK` 计数 `0→25`；`before` 腿 **0**；**外部反腿**：不可认领的身份 ⇒ `feed=-10000 ∧ find=-1` | ✅ **满足**（`win32_pts.c` `WpfLinuxWin32_PtsParaChainFeed` ＋ 生成件 `WpfLinuxTextParaChainProbe.FeedParagraph`；调用点 `TextParaClient.Linux.cs:107` `ValidateVisual`） |
| **(b) 五格逐段现取** | `Find/Para/PageId/SubSeq/SubClaimed/CpFirst/CpLim/SrcSlot/SrcHandle/State/Seq` 逐段现取；`mgd` 行 **×25**（25 个互异 `parah`、`page` 21 个值、`sub_seq` 25 个互异值） | ✅ **满足** |
| **(c) 与 `T-A69` 一一对应** | `src_slot == PtsTextSrcFind(parah)` ∧ `src_handle == PtsTextSrcHandle(该槽)` ∧ `cp`／`cch` 逐段相符 ⇒ **失配 0/25**；native `LinkOk(k)==1` **25/25** | ✅ **满足** |
| **(d) 两极化** | 探针 `SELFTEST mask=0x0f`；反腿副本 `mask=0x07`／`feed=0`／`rc=1`；反极腿 `[PARACHAIN]` 行 `25→0` | ✅ **满足** |
| **(e) 留痕** | `[PARACHAIN] rx=OK slot=… seq=… parah=… page=… sub_seq=… cp=[…,…) cch=… src_slot=… src=… state=… v=TEXT-PARA-IN-CHAIN` ×25 ＋ 托管 `[PARACHAIN] mgd …` ×25 | ✅ **满足** |

### 1.3 🔴 「满足」的**射程**（写死，防读宽）

1. **"进链"这一半满足，"排版"那一半不满足**：本趟入站的是**链坐标**（段身份／页同一性序号／`cp` 域）；**子轨**与**内容源句柄**是本侧**台账**读出的（认领所得／`T-A69` 表项地址）。`cLines`／`dcpFirst/dcpLim`／**行盒**一格**未填**（那些还要 `PRECOND-NO-LINE-BREAKER` ＋ 度量源）。
2. **"页身份"是托管给的同一性序号（写死）**：同 `PageContext` 实例 ⇒ 同号、异实例 ⇒ 异号（本趟 25 段落在 **21** 个页身份上：19 页各 1 段、2 页各 3 段）。本侧**只存不 deref**、**不主张**"页对象内存"。
3. **"进链"的牙与 `T-A69`／`T-A70` 不同（写死）**：那两条**不要求**身份在链上（"收下即存"）；本条**要求**（`not-in-chain` ⇒ **诚实拒绝、表内不出现该段**）—— 这正是 `PRECOND-NO-TEXT-PARA-IN-CHAIN` 的**字面**（"现链上是容器段落，`TextParaClient` 是另一族"⇒ 若**没进链**就必须**红**）。
4. **"同一窗内"的语义（写死）**：入站与对拍发生在**托管方法的一次调用窗内**（`TextParaClient.ValidateVisual` 内：喂料 ⇒ 立刻回读 ⇒ 逐格对拍）；native 对入参**只存值**（不跨窗持指针）。⚠️ 这**不是** LS 的 `LoCreateLine` 会话窗 —— 那一格仍缺（`PRECOND-LS-SESSION-DRIVER`）。

---

## §2 改动（逐处）

### 2.1 native：`src/WpfGfx.Linux.Native/src/win32_pts.c`

1. **`T-A69` 块内新增一个访问器**（**内容源句柄**；供"一一对应"核对）：
   `const void *WpfLinuxWin32_PtsTextSrcHandle(int k)` —— 句柄 ＝ `T-A69` **自持表项的地址**（在册期地址稳定 ⇒ 可作身份比对）；`k` 越界／魔数不符 ⇒ `NULL`（**不**用零值冒充"有源"）；**不可 deref**。
2. **新增一段 `T-A71` 块**（`:5760` 起）：
   - **常量／结构**：`WPF_PTS_PC_{MAX=8,CP_SPAN_MAX=65536,ST_NONE/UNSOURCED/SOURCED,MAGIC}` ＋ `wpf_pts_parachain`（`parah`／`page_id`／`sub_claimed`／`sub_seq`／`cp_first`／`cp_lim`／`src_slot`／`src_handle`／`state`／`seq`）。
   - **进链（唯一收口）** `WpfLinuxWin32_PtsParaChainFeed(parah, page_id, cp_first, cp_lim)`：先过**五条拒面**（`null-para`／`bad-page-id`／`cp-first-negative`／`cp-lim-before-first`／`cp-span-over-bound`）＋ **`not-in-chain`（＝该红必红的牙：`wpf_pts_sub_claim` 认不出该段身份 ⇒ 拒）** ⇒ 拒时**表内不出现该段** ＋ 具名 `[PARACHAIN] rx=REJECT …out=UNWRITTEN`；收时按**同一段身份**在 `T-A69` 表解析**内容源句柄**、认领所得的**子轨 `seq`**、`seq`、三态，打印具名 `rx=OK` 行。
   - **只读回读面**（导出 18 名）：`Count`／`Find`／`State`／`Seq`／`PageId`／`SubClaimed`／`SubSeq`／`CpFirst`／`CpLim`／`SrcSlot`／`Para`／`SrcHandle`／**`LinkOk`**／`Rx`／`RxGap`／`Unsourced`／`SelfCheck`／`SelftestMask`。
   - **两极化自检** `…PtsParaChainSelfCheck()`：夹具**子轨对象用 `wpf_pts_sub_new` 真造**（⇒ 其句柄**在链上可认领**）、**内容源用 `T-A69` 的 `…PtsTextSrcFeed` 真入站**；跑 4 位（正极：五格逐格相符 ＋ `LinkOk=1`／`UNSOURCED≠NONE`／反极必拒／**不在链上必拒**）；收尾**真销毁 ＋ 复原全部可观测状态**（含 `g_pts_sub_*`／`g_pts_hc_reading`／`g_pts_textsrc_*`／`g_pts_sub_claim_{ok,bad}`）；表位不足／泄漏 ⇒ `-1`（**不算绿**）。
   - **Fake 路径**：**不在主链**；反腿**只在仓外副本**（`~/tA71-work/replica-native/`，见 §3.4）。

> 🔴 **无假值纪律（四条）**：① 失败路径**一字不写**（表内无该段）；② **不在链上** ⇒ 诚实拒绝（**不**用"收下即存"冒充"进链"）；③ `UNSOURCED`（进链但无源）与 `NONE`（没进链）**不同形**；④ 越界 ⇒ **拒**（不截断、不静默）。

### 2.2 生成器：`build/PresentationFramework.Linux/reapply-patches.py`

| 项 | 内容 |
|---|---|
| `PARACHAIN_PROBE_FILE`／`PARACHAIN_PROBE_TEXT` | **新建件** `WpfLinuxTextParaChainProbe.Linux.cs`：`Enabled`（闸 `WPF_PARACHAIN_FEED`，**缺省开**、**只有**显式 `"0"` 才关）／`RefEq`（**引用相等**比较器）＋ `PageId(pageCtx)`（**同一 `PageContext` 实例 ⇒ 同一序号**，有界 `MaxPages=256`）／`FeedParagraph(parah, para, pageCtx)`（取 `ParagraphStartCharacterPosition` ＋ `text.Length` ⇒ `cp` 域；调 native ⇒ **立即回读**并逐格对拍（`state`／`page`／`sub`／`cp` 域／`src_slot`／`src_handle`）＋ native `LinkOk` ⇒ 一行 `[PARACHAIN] mgd …`；native 拒绝时单列一行 `v=REJECT-NOT-IN-CHAIN`） |
| `TPC_E_VV_REPL`（＋4 行） | 在 `TextParaClient` 的 `ValidateVisual` 内（既有 `T-A70` 喂料之后）加 `WpfLinuxTextParaChainProbe.FeedParagraph(_paraHandle, Paragraph, _pageContext);` —— **纯增**、不改任何既有控制流 |
| `materialize_derived()` | 多写一个**非派生新建件**（`_write_atomic`：`temp + fsync + os.replace`） |
| `PATCH_C` | 多一行 `<Compile Include="…/WpfLinuxTextParaChainProbe.Linux.cs" />` |

**幂等（现取）**：连跑两次，全部 `*.Linux.cs` ＋ `csproj` 的合并 `sha16` **两次同值** `8bf3bda259d6f04a` ⇒ `GEN_IDEMPOTENT=YES`。

### 2.3 为什么落在**托管侧**（不是纯 native）

native **看不到链坐标**：段身份（`_paraHandle`）／**所属页**（`_pageContext`）／`cp` 域（`ParagraphStartCharacterPosition`）都在**宿主**手上 ⇒ 只能**由托管发起**；native 侧只做**入站 ＋ 认领校验 ＋ 源解析 ＋ 保管 ＋ 回读 ＋ 自检**（**不**自造一格）。**子轨**与**内容源句柄**则是 native **自己的台账**读出的 —— 这正是"进链"的**本侧证据**（能认领 ＋ 能接到 `T-A69` 的源）。

---

## §3 成对读数

### 3.1 三腿（**只差权威 `.so`／`pf` 或一个 env**；同装置 `:231`；证据 `~/tA71-work/legs/`）

| 腿 | 权威 | env | 证据目录 | `LEGS_RUNNER` |
|---|---|---|---|---|
| `before` | `.so c5acc47490098ff0`／`pf 75f1a79441d01b16`（改前） | — | `~/tA71-work/legs/before/` | `PASS requested=2 obtained=2 refused=0` |
| `after` | `.so 53116d7456f62c44`／`pf 7cfcfa8c1f024b35`（改后） | — | `~/tA71-work/legs/after/` | `PASS requested=2 obtained=2 refused=0` |
| `rev`（**反极腿**） | 同 `after` | `WPF_PARACHAIN_FEED=0` | `~/tA71-work/legs/rev/` | `PASS requested=2 obtained=2 refused=0` |

同批工具（现取）：`runner_sha16=330a90f1f0ac28e4`／`session_sha16=f1a582d9ea9788c9`／`guard_sha16=ead59d60ccfc95b0`／`legs-to-env.py=ed290f41e5ae6432`；`device.txt`：`X_UP=yes display=:231`。

### 3.2 靶面成对（`grep -c` 现取，`app_g1.log`）

| 量 | `before`（改前） | `after`（改后／缺省） | `rev`（`FEED=0`） |
|---|---|---|---|
| `[PARACHAIN] mgd`（托管对拍行） | **0**（旧件无此面） | **25** | **0** |
| `… mgd … state=2`（SOURCED） | — | **25/25** | — |
| `… mgd … sub=1`（子轨可认领） | — | **25/25** | — |
| `… mgd … link=1`（与 `T-A69` 一一对应） | — | **25/25** | — |
| `… mgd … mism=0` | — | **25/25** | — |
| `… mgd … v=REJECT-NOT-IN-CHAIN` | — | **0** | — |
| `[PARACHAIN] rx=OK`（native 进链行） | **0**（旧件无此面） | **25** | **0** |
| `[PARACHAIN] rx=REJECT` | **0** | **0** | **0** |
| 互异 `parah`（`[PARACHAIN]` 行内） | — | **25** | — |
| 互异 `page`（`[PARACHAIN]` 行内） | — | **21** | — |
| `[HC-UNHANDLED]` ／ `entry point named` ／ `failfast+unrec` | 0 ／ 0 ／ 0 | 0 ／ 0 ／ 0 | 0 ／ 0 ／ 0 |

**逐段五格现取（样例，逐字）**：

```
[PARACHAIN] mgd parah=0x58158b45a104 page=1 cp=[2,884) n=882 rc=0 slot=0 state=2 sub=1 src_slot=0 src=0x58158a9373c0 link=1 mism=0 v=TEXT-PARA-IN-CHAIN
[PARACHAIN] mgd parah=0x581590282af4 page=2 cp=[703,741) n=38 rc=0 slot=1 state=2 sub=1 src_slot=1 src=0x58158a93b400 link=1 mism=0 v=TEXT-PARA-IN-CHAIN
[PARACHAIN] mgd parah=0x58158f7c3d54 page=3 cp=[754,767) n=13 rc=0 slot=2 state=2 sub=1 src_slot=2 src=0x58158a93f440 link=1 mism=0 v=TEXT-PARA-IN-CHAIN
```

```
[PARACHAIN] rx=OK slot=0 seq=1 parah=0x58158b45a104 page=1 sub_seq=8 cp=[2,884) cch=882 src_slot=0 src=0x58158a9373c0 state=SOURCED v=TEXT-PARA-IN-CHAIN
[PARACHAIN] rx=OK slot=1 seq=2 parah=0x581590282af4 page=2 sub_seq=15 cp=[703,741) cch=38 src_slot=1 src=0x58158a93b400 state=SOURCED v=TEXT-PARA-IN-CHAIN
```

**`cch` 全谱（现取 `sort -u`）**：`{9,12,13,16,22,38,40,568,588,882}`；**`page` 全谱**：`1…21`（21 个值）；**`sub_seq` 全谱**：25 个**互异**值（`8,10,12,15,20,23,26,29,32,35,38,41,44,46,48,51,56,59,62,65,68,71,74,77,79`）。

**与 `T-A69` 内容源**一一对应**现取（逐段对拍，脚本 `python3` 现跑）**：
```
TEXTSRC parah: 25  PARACHAIN parah: 25
交集: 25  只在TEXTSRC: 0  只在PARACHAIN: 0
一一对应失配数: 0        （判定：src_slot==PtsTextSrcFind(parah) ∧ cp 相符 ∧ cch 相符 ∧ state==2 ∧ sub==1 ∧ link==1 ∧ mism==0）
页数: 21  每页段数: [1×19, 3, 3]
```

### 3.3 探针（`dlopen` 直调；正极 ＝ 主链 `.so`）

> ⚠️ **口径（写死）**：本条的**正极**（"链上段 ＋ 有源"）**只能由 native 侧造**（"链上对象"＝ `wpf_pts_sub_new` 的产物，探针无此导出）⇒ 正极由**自检**在 native 内用夹具完成；探针在外部做**负面面**（**不在链上 ⇒ 必拒**）与**越界哨兵**。

```
EXPORTS present=20/20
== selftest ==
SELFTEST mask=0x0f rc=4/4
SELFTEST2 mask=0x0f（幂等：自检不改变可观测状态）
== negative (not in chain) ==
NOCHAIN feed(local)=-10000 feed(0x5a5a5a5a)=-10000 find(local)=-1 find(0x5a5a5a5a)=-1
== bad args ==
FEED(null)=-10000 FEED(badpage)=-10000 FEED(negcp)=-10000 FEED(lim<first)=-10000
OOB state=-1 cpfirst=-1 cplim=-1 srcslot=-1 link=0 para=(nil) srch=(nil)
== counters ==
COUNT=0 RX=0 RXGAP=12 UNSOURCED=0
PROBE selftest_mask=0x0f nochain_rejected=1 badargs_rejected=1 nosource_find=-1 rc=0   （MAIN_RC=0）
```

### 3.4 🔴 **反腿副本**（认领**只记不拒**＝静默半通；该红必红）

`~/tA71-work/replica.so` ＝ **`15b861d530151d3f`**（仓外副本：把进链收口的 `not-in-chain` 闸由"`if (!claim) 拒`"改成"`else { 只记不拒 }`"，其余逐字同 —— 即"**不在链上也收下**"的静默半通形态；**主链一字未含该路径**）。

```
SELFTEST mask=0x07 rc=PARTIAL
NOCHAIN feed(local)=0 feed(0x5a5a5a5a)=0 find(local)=-1 find(0x5a5a5a5a)=-1
PROBE selftest_mask=0x07 nochain_rejected=0 badargs_rejected=1 nosource_find=1 rc=1   （REPLICA_PROBE_RC=1）
```

⇒ **该红必红（两条独立证据）**：① **自检位** `0x0f→0x07`（**bit3「不在链上必拒」当场灭**）；② **探针反腿**：`feed(local)` 由 `-10000` 变 **`0`** ⇒ "**不在链上的身份也被收下**"。⇒ 本条的"**进链**"**不是恒真断言**（它能把"没验链就收下"照出来）。

### 3.5 反极腿（`WPF_PARACHAIN_FEED=0`；同一权威件）

| 量 | `after`（缺省） | `rev`（`=0`） |
|---|---|---|
| `[PARACHAIN]` 行总数 | **50**（25 native ＋ 25 mgd） | **0** |
| 本趟自定判据 `PARACHAIN_GUARD`（＝ `mgd>0 ∧ 全部 state=2 ∧ 全部 sub=1 ∧ 全部 link=1 ∧ 全部 mism=0 ∧ 全部 rc=0 ∧ REJECT 0`；命令见 §4） | **PASS** | **FAIL**（无正读数 ⇒ 红） |
| `PTS_GUARD`／`PTS_COLORANCHOR`／症状门 | `PASS legs=2/2`／`PASS hits=3`／逐格 | **同**（如实记：本通道**观测用、不承重像素** ⇒ 这两门**不因它翻红**） |

> ⚠️ **如实披露（防读宽）**：本通道**不改变渲染**，所以反极腿的 `PTS_GUARD`／`PTS_COLORANCHOR` **两腿同值**（`colors 1220/636`、色锚不变）⇒ "无进链 ⇒ 该红必红"**由本趟自定判据 ＋ §3.4 副本承担**，**不**由页门承担（页门在这条面**结构性不可分**）。

### 3.6 症状门 ＋ 帧面成对

| 量 | `before` | `after` | `rev` |
|---|---|---|---|
| `k24` | `alive=yes app_rc=143 magenta=0 colors=1220 ae=220019 ink=480000 failfast=0` | **同** | **同** |
| `k23` | `alive=yes app_rc=143 magenta=0 colors=636 ae=136292 ink=480000 failfast=0` | **同** | **同** |
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
| `nm==exports` | `nm -D --defined-only` ＝ **798** ＝ `exports.txt` 行数；**逐名 `diff` 零差异**；**新增 20 名、无消失**（＋`WpfLinuxWin32_PtsParaChain{Feed,Count,Find,State,Para,PageId,SubSeq,SubClaimed,CpFirst,CpLim,SrcSlot,SrcHandle,LinkOk,Seq,Rx,RxGap,Unsourced,SelfCheck,SelftestMask}` 19 名 ＋ `WpfLinuxWin32_PtsTextSrcHandle` 1 名） | 0 |
| `PTSGAP` | `PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=53116d7456f62c44 exports=798`（`tool/ops/impl` **未动**；`PTSGAP_HISTORICAL=n=11`；`PTSGAP_CITED=PASS refs=1`） | 0 |
| `DEFREG` | `PASS declared=225 route_ids=225`；`DECLDRIFT=0 keys=-` | 0 |
| `REPORTID` | `PASS files=346 ids=2257 declared=225`（本件落盘前 `345` ⇒ 落盘后 `346`，`+1` 即本件） | 0 |
| `HANDOFF_MV` | `PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none`（已按第 `28` 条契约在 `HANDOFF-NEXT.md` 文件尾**只增**追写机器值契约行，`inputs_fp d59710f3…→eefad720…`） | 0 |
| `GEN_IDEMPOTENT` | 连跑两次：全部 `*.Linux.cs` ＋ `csproj` 的合并 `sha16` ＝ `8bf3bda259d6f04a`（两次同值） | 0 |
| **本趟自定判据** `PARACHAIN_GUARD` | `mgd>0 ∧ 全部 state=2 ∧ 全部 sub=1 ∧ 全部 link=1 ∧ 全部 mism=0 ∧ 全部 rc=0 ∧ REJECT 0`（命令：`grep -a '\[PARACHAIN\] mgd' <leg>/app_g1.log` 取计数）；`after` ⇒ **PASS**（25/25/25/25/25/25）；`rev` ⇒ **FAIL**（0 条正读数） | 0／1 |

---

## §5 逐件 `sha16`（现取）

| 件 | 改前 | 改后 |
|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `4ec3e0dfe2950b06`（769019 B／10416 行） | **`6ad1500b59cd7cf0`**（790224 B／10710 行） |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so`（**非仓内件**） | `c5acc47490098ff0`（524008 B） | **`53116d7456f62c44`**（533832 B） |
| `src/WpfGfx.Linux.Native/bin/exports.txt`（**非仓内件**） | `92c091935f07df42`（778 行） | **`3fc15b59b35739f3`**（798 行） |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `8f7099defa925673`（629 行） | **`a9eb06731f1f3b42`**（649 行） |
| `build/PresentationFramework.Linux/reapply-patches.py`（生成器） | `12b69807e6846637`（160656 B） | **`0fdbadc739470b47`**（172833 B） |
| `…/TextParaClient.Linux.cs`（重产件） | `4e35c14a1cf8809e`（211990 B） | **`b88451d6edaa28d0`**（212328 B；＋4 行：喂料调用 ＋ 注释） |
| `…/PresentationFramework.Linux.csproj`（重产件） | `e4dbecf5e0b3b752` | **`f19cfdaeebce4892`**（＋2 行：新件 `<Compile Include>`） |
| `…/WpfLinuxTextParaChainProbe.Linux.cs`（重产件 · **本趟新建**） | — | **`a1a8eea8212f23c1`**（9375 B／158 行） |
| `build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll`（**非仓内件**） | `75f1a79441d01b16`（6149120 B） | **`7cfcfa8c1f024b35`**（6152704 B） |
| `docs/ROUTES.md` | `57a77e0df44834a6`（1131 行） | **`9e126bd9443c8c65`**（1132 行） |
| `build/MilBridge/HANDOFF-NEXT.md` | `6650fe2f5667655a`（767 行） | **`4d0fc80d8280930c`**（770 行；文件尾**只增**两段机器值契约行） |
| `docs/WAVE66-PREREGISTRATION.md`（**冻证据**） | `bf6b683d94549087` | **未变**（`bf6b683d94549087`） |

> ⚠️ 生成器**重产件**里 `PtsCache.Linux.cs`／`FlowDocumentView.Linux.cs`／`FlowDocumentPage.Linux.cs`／`PtsPage.Linux.cs`／`PtsHelper.Linux.cs`／`FigureParaClient.Linux.cs`／`ContainerParaClient.Linux.cs`／`FlowDocumentFormatter.Linux.cs`／`FlowDocumentPaginator.Linux.cs`／`WpfLinuxChainProbe.Linux.cs`／`WpfLinuxTextSrcProbe.Linux.cs`／`WpfLinuxCpDcpMapProbe.Linux.cs` **逐字节未变**（幂等现取）。

---

## §6 诚实边界（**防读宽**，逐条）／具名 `NOINFO`

1. 🔴 **本条只判"文本段落在链上可寻址 ∧ 五格逐段现取 ∧ 与 `T-A69` 一一对应 ∧ 可两极化"**；**不**判"排版前进"、**不**判"`W` 解除"（三腿四帧逐字节同 ⇒ **零像素位移**）。
2. 🔴 **"进链"不是"本侧是作者"**：段身份／页身份／`cp` 域由**托管（宿主）**产出；native **只收／只认领／只解析／只回读**（`P1-layout-content-criteria.md:146` 的 `P9` 边界仍成立）。
3. 🔴 **"子轨"的射程**：`sub_seq` ＝ **认领所得的那个本侧 `wpf_pts_subtrack` 对象**的台账序号（`T-A25` 体例：`FsQuerySubtrackParaList` 交回的本侧自有对象句柄）；它**不**主张"该段在托管侧的父子结构"，也**不**主张"子轨里的段数"。
4. 🔴 **"页身份"的射程（写死）**：它是**托管侧**给该 `PageContext` **实例**分配的**同一性序号**（引用相等 ⇒ 同号）；本侧**只当不透明 token** 存与回读，**不 deref**、**不主张**"页对象内存"、**不**跨窗当身份用（有界表 256，超出即重开表）。
5. 🔴 **"一一对应"的射程**：`src_slot`／`src_handle` **只接**"同段身份 ⇒ 同 `T-A69` 表项"这一件事；它**不**主张"该字符序列的**内容**与某行/某盒对应"（那是排版面）。
6. 🔴 **"进链 ≠ 排版"**：本块**不**填任何几何／行盒／`cLines`／`dcp` 区间；`PRECOND-NO-LINE-BREAKER`／`PRECOND-LS-SESSION-DRIVER`／`C2`（`plsrun` 那一半）**仍在册**；`FullText` 只在 LS 造型窗内非空（`LineServicesCallbacks.cs:3448`），而本移植**绕过 LS 造型**（`build/PresentationCore.Linux/TextFormatterImp.Linux.cs`）⇒ 该格**结构性不可达**（**不冒充**）。
7. 🔴 **`PTS_GUARD`／`PTS_COLORANCHOR` 在本条面上不可分**：本通道**观测用**、**不承重像素** ⇒ 反极腿这两门**同值**；"无进链 ⇒ 该红必红"由**自定判据 ＋ §3.4 副本**承担。
8. 🔴 **有界性（如实记）**：在册条数 ≤ `8`、单段 `cp` 跨度 ≤ `65536`；**表满 ⇒ 有界复用最旧槽**（具名行带 `slot=`）。本趟 25 段**落在 8 槽上轮转**（`slot=0..7` 循环）⇒ 回读面是"**最近 8 段**"视图，**不是**全量台账（**明示，防读成全量**）。
9. **具名 `NOINFO`（逐条给"消掉条件"）**：
   - **`NOINFO-PARACHAIN-LS-WINDOW`**：本趟喂料点是 `TextParaClient.ValidateVisual`（**托管方法窗**），**不是** LS 的 `LoCreateLine` 会话窗。**消掉条件**：本侧成为重入方并驱动 `Lo*`（`PRECOND-LS-SESSION-DRIVER`）。
   - **`NOINFO-PARACHAIN-PAGE-IDENTITY`**：本侧**没有**"页对象"可认领 —— 页身份是**托管给的序号**（非 native 对象）。**消掉条件**：native 侧有可认领的页/子页对象与该段**同窗**绑上（承 `PRECOND-LS-SESSION-DRIVER`）。
   - **`NOINFO-PARACHAIN-CROSS-PAGE`**：粒度 ＝ **单段落**（承契约 `:100`）；"跨页/整页"结论**不由本条宣布**（本趟只**顺带**现取到 25 段分布在 21 个页身份上）。
10. **未跑整趟 `verify-all`**（照派单）；本节所有"不得读成绿"的口径照在册红榜 `P1–P10`。

---

## §7 遗留（下一增量具名靶）

- **`W` 余项**：`C2`（`plsrun` 那一半）／`PRECOND-NO-LINE-BREAKER`／`PRECOND-LS-SESSION-DRIVER` **未解除**（`PRECOND-NO-TEXT-PARA-IN-CHAIN` 的**字面**已由本条推进为"**有可现取的真读数**"，但本条**不**授权任何判据放宽）；本件**不**授权任何判据放宽。
- **最近的一格（可选）**：把进链表的**有界视图**升为"按证据序号可追"（例如每段一条 `ev_seq`；今天只有"最近 8 段"）。
- **越级项（须队长裁定）**：`PRECOND-LS-SESSION-DRIVER`（本侧成重入方）＋ 度量源（`LS-CB-M1` 的 `GetRunTextMetrics`／`GetRunCharWidths`）—— 二者是判据 `:100` 的六条合取之 ④（行盒）的真前置；本条**未**触碰。
`P1-TAIL2-PARACHAIN 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ f3cf58b7f698c2a4（末行＝本行）`

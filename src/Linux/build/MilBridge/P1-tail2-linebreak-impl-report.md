# `P1-tail2` · `T-A73` · **行断器（`PRECOND-NO-LINE-BREAKER`；`W` 合取③）**（`TASK-0307` 增量）—— 实现报告

**判决**：把在册前置 **`PRECOND-NO-LINE-BREAKER`**（`build/MilBridge/P1-layout-content-criteria.md:113`：「**`PRECOND-NO-LINE-BREAKER`**：本侧无行断器（LS 族 0 实现）。」；`build/MilBridge/P1-tail2-dingrecon.md:93` §3.2 列为 `W` 合取**第三条**）落地成 native 侧一条**行断点台账（按段身份可寻址）＋ 逐断点只读回读面（断点 `cp` 序列 ＋ 逐断点最小 `LsLInfo` 骨架）＋ 两极化自检**：**托管侧**（生成器重产件 `WpfLinuxLineBreakProbe.Linux.cs` ＋ `TextParaClient.Linux.cs` 的 `ValidateVisual` 一处调用）在**同一窗内**按**段身份**触发 native 的收口 `WpfLinuxWin32_PtsLineBreakFeed`；native 当场过**三面牙**（① 段身份须 `wpf_pts_sub_claim` 可认领＝`T-A71` 进链；② 须有 `T-A69` 内容源；③ 须有**托管真排版**交回的行记录 `fl_line[]` 可回填），随后**按可诚实规则自算**（从内容源字符序列数出**强制断行序列**数 `n_hard`）并与**托管真断点**做两条可证伪不变量对拍：**域内自洽**（`dcp` 严格递增 ∧ 首断点 > 0）＋ **跨域计数不变量**（`n_brk >= n_hard`）；任一破 ⇒ **诚实拒绝**（`brk-not-monotonic`／`brk-first-not-after-start`／`brk-count-vs-content`）。**真腿现取（`after`）**：`[LINEBREAK] mgd … rc=0 … n_brk=… n_hard=… mono=1 first=1 cover=1 dcp0=… dcpN=… seq=… mism=0 v=LINE-BREAKER-SET` **×25** ＋ native `[LINEBREAK] rx=OK …` **×25**（`n_brk ∈ {1,2,6,8}`／`n_hard ∈ {0,2,8}`／`cover=1` 全中；首段 `cch=882 n_brk=8 n_hard=8`）；`before`／`rev` 均 **0** 条。**两极化**：dlopen 探针 `[LINEBREAK-SELFTEST] mask=0x0f`（4/4：正极／反极必拒／真断点非单调必红／跨域计数不变量破必红）；**反腿副本**（三条判据门在 `WPF_PTS_LB_FAKE` 上＝静默半通形态）⇒ `mask=0x03`、`PROBE_RC=1`（**该红必红**）；**反极腿**（`WPF_LINEBREAK_FEED=0`）⇒ `[LINEBREAK]` 行 **0 条**。**零回归**（三腿四帧**逐字节相同**，`AE=0`；`PTS_GUARD=PASS`／`PTS_COLORANCHOR=PASS hits=3`／`PTS_ENFE=PASS total=0`）。**导出面**：`exports 824→846`（逐名 **+22**、**无消失**），`nm==exports==846`；`PTSGAP`／`DEFREG`／`REPORTID`／`HANDOFF_MV` rc=0。🔴 **如实划界（本件的核心判决）**：**行断器 ≠ 排版前进** —— 断点 `dcp` 由**托管真排版**产出（`pfnFormatLine` 真返回值）、`cp_first` 由 `T-A69` 给出，本侧**只收／只认领／只对拍／只回读**；且**内容源是文本域（`TextRange.Text`）而 `fl_line[]` 的 `dcp` 是排版域（含元素边界符号）⇒ 不可逐点换算** ⇒ 本块**只做跨域计数不变量 ＋ 域内自洽**（具名 `NOINFO-linebreak-domain-mismatch`）；`C2` 的 `plsrun` 那一半／`PRECOND-NEW-CALLBACK-FACE` **仍在册** ⇒ `W` 整体**未解除**。

- **读时**：`2026-10-02T00:1x–00:3x+0800`（本席现取；各条另注）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`（**未 `git add/commit/push`**）；开工 `HEAD=8958fd4`（`T-A72` 结账后）；⚠️ 如实记：开工时工作树**已带**一处未提交改动 `M build/PresentationFramework.Linux/PtsCache.Linux.cs`（＝`T-A72` 那趟生成器的重产件，`git status` 现取；**本席未手改其内容**）。
- **改前件备份（仓外 `~/tA73-work/bak/`，`cp -p`，取在**任何写之前**）**：`win32_pts.c`（`ab4b685704b53ed3`／817199 B／11087 行）／`bin/libwpfwin32.so`（`630cefb6c7bdf0f0`／544008 B）／`bin/exports.txt`（`e5675ec32f7323df`／824 行）／`tools/pts-gap-decl.txt`（`9a2212296af5ea24`／674 行）／`build/PresentationFramework.Linux/reapply-patches.py`（`80c84ee298ca1b6d`／187697 B）／其重产件（`bak/generated/` 全套）／`PresentationFramework.dll`（`94a73efe3bc68808`）／`docs/ROUTES.md`（`4e0239f346632268`／1133 行）／`build/MilBridge/HANDOFF-NEXT.md`（`59892f54ad107b0b`／774 行）。
- **写域（逐件）**：`src/WpfGfx.Linux.Native/src/win32_pts.c`（**加一段 `T-A73` 块**：行断点台账 ＋ 逐断点只读回读面 ＋ 两极化自检）／`src/WpfGfx.Linux.Native/bin/exports.txt`（**构建重产**，非手改）／`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（DECL 行 `so16`／`exports` 跟权威件换 ＋ 只增一段 `T-A73` 重锚）／**生成器** `build/PresentationFramework.Linux/reapply-patches.py`（新增 `LBREAK_PROBE_FILE`／`LBREAK_PROBE_TEXT` ＋ `TPC_E_VV_REPL` 一处调用 ＋ `materialize_derived()` 写新件 ＋ `PATCH_C` 一行 `<Compile Include>`）／**其重产件**（`WpfLinuxLineBreakProbe.Linux.cs` **新建件**、`TextParaClient.Linux.cs`、`PresentationFramework.Linux.csproj`）／**复述位现值位**（`docs/ROUTES.md` `TASK-0307` 行加一条 dated 结账；`build/MilBridge/HANDOFF-NEXT.md` 文件尾机器值契约追写）／**新建载体** 本件。
- **未改**（如实体例）：`docs/WAVE66-PREREGISTRATION.md`（冻证据 `w66pre16=bf6b683d94549087` 未动）；`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`src/WpfGfx.Linux.Native/src/win32_classification.c`（本趟**未移动**它们所持的 `tool/ops/impl` 三格 ⇒ `PTSGAP` 判据**要求**它们**不动**，见 §4）；`bin/libwpfwin32.so`／`bin/exports.txt`／`build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` 属**构建产物**（非仓内件）。
- **黑名单遵守**：未动 `build/MilBridge/tools/**`（**只读跑**判据件）／`verify-all.sh`／`build/close-wave.sh`／`build/shims/**`／`upstream/**`（只读）；**未跑**整趟 `verify-all`；未改相位位；未 `git add/commit/push`。
- **重活**：**3 趟 native 构建**（主链 2 ＋ 仓外反腿副本 1）＋ **1 趟托管构建**（`0 警告 0 错误`，`24.5 s`）＋ **1 趟跑器**（`before`／`after`／`rev`，共 **6 条腿**），全走 `bash ~/heavy-slot.sh --min-avail 2000 --max-hold 900/1500 --wait 3600 -- <cmd>`（逐趟 `HEAVYSLOT=ACQUIRED/MEMOK/RELEASED rc=0`）；进程只按 PID；显示位只用跑器自分配的号（`DISPLAY_PICK :231`）；禁 `sleep` 轮询；写前 `cp -p`；`temp+rename`（生成器 `_write_atomic`）；模式守恒。
- **口径**：一切读数**本席现取**（`sha256sum`／`nm -D --defined-only`／`diff`／`grep -c`／`gcc` 编译的 `dlopen` 探针 `~/tA73-work/probe`／`compare -metric AE`／只读跑 `bash build/MilBridge/tools/{pts-gap-count-check,pts-pages-guard,defect-registry-check,report-id-domain-check,handoff-machine-values-check}.sh`）。凡引他件处一并标注。

---

## §0 结论速览（自包含）

1. ✅ **「行断器」= 真台账（现取）**：`after` 腿 `app_g1.log` 里 native `[LINEBREAK] rx=OK … state=VALUE v=LINE-BREAKER-SET` **25 条** ⇒ 托管在真应用里对 **25 个文本段落**逐个触发本侧收口、**逐个成功**；`before` 腿 **0 条**（旧件无此面）。
2. ✅ **断点 `cp` 序列 ＋ 最小 `LsLInfo` 骨架逐段可现取**：`[LINEBREAK] mgd … cp=[…) cch=… n_brk=… n_hard=… mono=1 first=1 cover=1 dcp0=… dcpN=… mism=0` **×25**（`cch ∈ {9,12,13,16,22,38,40,568,588,882}`；`n_brk ∈ {1,2,6,8}`；`n_hard ∈ {0,2,8}`）⇒ **逐段对拍零失配**。
3. ✅ **`native 自算 vs 托管真断点` 的两条可证伪不变量全中**：`mono=1`（`dcp` 严格递增）／`first=1`（首断点 > 0）／`cover=1`（`n_brk >= n_hard`）**25/25**。**首段**（`cch=882`）`n_brk=8 n_hard=8` ⇒ **真排版 8 行恰对内容源里 8 条强制断行**（该不变量在本移植的**真数据上**被走到，不是恒真）。
4. ✅ **两极化（该红必红）**：① 探针 `[LINEBREAK-SELFTEST] mask=0x0f`（4/4：正极／反极必拒／**真断点非单调必红**／**跨域计数不变量破必红**）＋ 幂等复算同值；② **反腿副本**（`~/tA73-work/replica-native/bin/libwpfwin32.so 6857040231585236`，把三条判据门在 `WPF_PTS_LB_FAKE` 上＝静默半通形态）⇒ `mask=0x03`（bit2／bit3 灭）、`PROBE_RC=1`（**该红必红**）；③ **反极腿**（`WPF_LINEBREAK_FEED=0`，同一权威件）⇒ `[LINEBREAK]` 行 **0 条**。
5. ✅ **零回归**：`.so 630cefb6c7bdf0f0（改前）→ df27801beb222f05（改后）`／`pf 94a73efe3bc68808 → 93f0368dac89f9c2`；三腿（`before`／`after`／`rev`）四帧**逐字节相同**（`AE=0`；`boot b21eb530afd3c66c`／`k23 10d0b9d54e649c10`／`k24 0bdb2dfd05952bc9`／`last 10d0b9d54e649c10`）、症状门逐格同；`PTS_GUARD=PASS legs=2/2`／`PTS_COLORANCHOR=PASS k=24 hits=3`／`PTS_ENFE=PASS total=0` **未回退**。
6. ✅ **门禁四件（现取）**：`nm -D --defined-only` ＝ `exports.txt` ＝ **846**（逐名 `diff` 零差异；**+22 无消失**）；`PTSGAP=PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=df27801beb222f05 exports=846`（rc=0）；`DEFREG=PASS declared=225 route_ids=225`（rc=0，`DECLDRIFT=0`）；`REPORTID=PASS files=347 ids=2257 declared=225`（rc=0）；`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0`（rc=0）。
7. 🔴 **如实划界（本件的核心判决）**：本条**只**判「**对给定段产出断点 `cp` 序列 ＋ 逐断点最小 `LsLInfo` 骨架 ∧ 只按可诚实规则（内容源强制断行）自算 ∧ 与托管真断点在两条不变量上逐段对拍 ∧ 可两极化**」。它**不**判「排版前进」、**不**判「`W` 解除」——`C2` 的 `plsrun` 那一半／`PRECOND-NEW-CALLBACK-FACE` **仍在册**；**行断器 ≠ 排版**（三腿四帧逐字节同 ⇒ **零像素位移**）。

---

## §1 「行断器」的**准入判据**（现取：件:行 ＋ 满足／不满足）

> **判据一律逐字引自**已登载的判据件（件:行）；行号只保证本次有效（内容锚原文一并给）。

### 1.1 在册出处（逐字）

| 角色 | 件:行 | 现取原文（要点） |
|---|---|---|
| **前置本体（本条的靶）** | `build/MilBridge/P1-layout-content-criteria.md:113` | 「**`PRECOND-NO-LINE-BREAKER`**：本侧无行断器（LS 族 0 实现）。」 |
| **`W` 合取③** | `build/MilBridge/P1-tail2-dingrecon.md:93`（§3.2） | 「**行断器** —— `PRECOND-NO-LINE-BREAKER`（同上 `:113`）。」 |
| **准入的形式条件** | `P1-tail2-dingrecon.md:98` | 「**当且仅当** `W` 每项在同一趟腿上有**可现取的真读数／具名留痕**（`P10`）时，"内容层那一波"＝**已落地**。」 |
| **前置三分（缺一不可）** | `P1-layout-content-criteria.md:102` | 「**前置（三条，缺一不可）**：**(i)** 内容源入站通道；**(ii)** 行断器；**(iii)** 链上真的出现**文本段落**。」 |
| **禁伪造（`P3`／`P8` 家族）** | `P1-layout-content-criteria.md:124`（§6 风险①） | 「🔴 **伪造风险**：无行断而答 `cLines/dcp` ⇒ **native 自造**（红 `P3`／`P8`）。」 |
| **源在谁手上（`P9` 边界）** | `P1-layout-content-criteria.md:146` | 「**源在宿主侧**（托管 `TextContainer`/`TextFormatter`……）……本件只判"**取它要开新面**"」 |
| **粒度（承契约）** | `build/MilBridge/P1-ls-provenance-contract.md:100` | 「粒度：**单段落**」（本件不宣布跨页/整页结论） |
| **`T-A67` 的现取（真依赖）** | `P1-tail2-dingrecon.md:118`（§4.1-03） | 「**断行器＋内容**：出参 `LsBreaks`（断点集＋逐断点 `LsLInfo`）＝**排版产物**」 |

⇒ **本条把「行断器」判据化（写死）为五条合取**：**(a) 台账可寻址**（按**段身份**查得；段身份须**可认领**才收，否则诚实拒绝）；**(b) 断点 `cp` 序列 ＋ 逐断点最小 `LsLInfo` 骨架逐段现取**；**(c) 只按可诚实规则自算**（内容源强制断行；**不伪造度量**）**并与托管真断点对拍**（两条可证伪不变量）；**(d) 两极化**（断点不符 ⇒ 必红；`WPF_LINEBREAK_FEED=0` ⇒ 0 条）；**(e) 留痕**（`[LINEBREAK]` 具名行）。

### 1.2 逐条现取（满足／不满足）

| # | 判据 | 现取读数（`after` 腿／探针） | 判定 |
|---|---|---|---|
| **(a) 可寻址＋进链有牙** | 段身份必须能在本侧台账**按对象身份认领**（`wpf_pts_sub_claim`，承 `T-A71`）⇒ `[LINEBREAK] rx=OK` 计数 `0→25`；`before` 腿 **0**；外部反腿：未登记身份 ⇒ `feed=-10000` | ✅ **满足**（`win32_pts.c` `WpfLinuxWin32_PtsLineBreakFeed` ＋ 生成件 `WpfLinuxLineBreakProbe.FeedParagraph`；调用点 `TextParaClient.Linux.cs:115` `ValidateVisual`） |
| **(b) 逐段现取（cp 序列 ＋ 骨架）** | `Find/NBrk/NHard/CpFirst/CpLim/Cch/DcpAt/CpAt/Info/Mono/FirstOk/CoverOk/State/Seq` 逐条现取；`mgd` 行 **×25** | ✅ **满足** |
| **(c) 可诚实自算 ＋ 对拍** | native 从内容源自算 `n_hard`；两条不变量 `mono`／`first`／`cover` **25/25**；`mism=0` **25/25** | ✅ **满足** |
| **(d) 两极化** | 探针 `SELFTEST mask=0x0f`；反腿副本 `mask=0x03`／`rc=1`；反极腿 `[LINEBREAK]` 行 `50→0` | ✅ **满足** |
| **(e) 留痕** | `[LINEBREAK] rx=OK slot=… seq=… parah=… cp=[…) cch=… n_brk=… n_hard=… mono=… first=… cover=… dcp0=… dcpN=… state=VALUE v=LINE-BREAKER-SET` ×25 ＋ 托管 `[LINEBREAK] mgd …` ×25 | ✅ **满足** |

### 1.3 🔴 「满足」的**射程**（写死，防读宽）

1. **"断点集合可现取 ∧ 可对拍"这一半满足，"native 自己断行"那一半不满足**：断点 `dcp` 由**托管真排版**产出（`pfnFormatLine` 真返回值，经 `T-A33` 记进 `fl_line[]`）；`cp_first` 由 `T-A69` 给出。本侧**唯一自算**的是**内容源里的强制断行序列计数**（`LF`/`CR`/`NEL`/`LS`/`PS`，`CRLF` 视作一条）—— 这是**不依赖度量**的确定性规则。**软断行（按宽度换行）本侧推不出**（无度量源）⇒ **不冒充**。
2. 🔴 **域不同（本件核心划界）**：内容源是**文本域**（`TextRange.Text` 的字符序列），而 `fl_line[]` 的 `dcp` 是**排版域**（含元素边界符号）。现取反例：某段 `[LINEBREAK] rx=OK … cch=38 … dcpN=41` ⇒ `text.Length=38` 而 `dcpLim=41`（差 3 个边界符号）⇒ 两域**不可逐点换算**。⇒ 本块**只做**：① **域内自洽**（真断点 `dcp` 严格递增 ∧ 首断点 > 0）；② **跨域计数不变量**（`n_brk >= n_hard`）；**不**跨域对点、**不**伪造映射（具名 `NOINFO-linebreak-domain-mismatch`）。
3. **"最小 `LsLInfo` 骨架"的射程（写死）**：本侧只给**能诚实推出**的三格 —— `cpFirstVis`（该行起始 `cp`；首行 ⇒ `cp_first`）／`cpLim`（＝该断点 `cp`；对应 `cpLimToStay`/`cpLimToContinue`）／`fFirstLineInPara`（i==0）。**度量字段（`dvr/dvp` ascent/descent、`vaAdvance`、`EffectsFlags`…）本侧一个都不给**（`Info(k,i,3) == -1`，自检 bit0 断言此项）—— 本侧**无度量源**（`P1-layout-content-criteria.md:112` 的 `PRECOND-NO-TEXT-SOURCE` 与 LS 回调面 `LS-CB-M1` 的 `GetRunTextMetrics`／`GetRunCharWidths` 未接）⇒ **不许伪造度量**（`P3`／`P8`）。
4. **"同一窗内"的语义（写死）**：触发与回读对拍发生在**托管方法的一次调用窗内**（`TextParaClient.ValidateVisual` 内：触发 ⇒ 立刻回读 ⇒ 逐格对拍）。native 对入参**只存值**（不跨窗持指针）。⚠️ 这**不是** LS 的 `LoCreateLine` 会话窗 —— 那一格仍缺（`C2` 的 `plsrun` 那一半）。
5. **"行断器 ≠ 排版前进"**：本块**不**改任何几何／行盒／渲染（三腿四帧逐字节同 ⇒ **零像素位移**）。

---

## §2 改动（逐处）

### 2.1 native：`src/WpfGfx.Linux.Native/src/win32_pts.c`（新增一段 `T-A73` 块，附在文件末）

1. **常量／结构**：`WPF_PTS_LB_{MAX=8,ST_NONE/EMPTY/VALUE,MAGIC}` ＋ `wpf_pts_linebreak`（`parah`／`cp_first`／`cp_lim`／`cch`／`n_hard`／`n_brk`／`dcp[32]`／`cp[32]`／`mono`／`first_ok`／`cover_ok`／`state`／`seq`）。
2. **入站（唯一收口）** `WpfLinuxWin32_PtsLineBreakFeed(parah)`：过**三面牙**（`null-para`／`not-in-chain`（`wpf_pts_sub_claim`）／`no-text-source`（`T-A69`）／`no-line-ledger`（`wpf_pts_fl_usable`））＋ **两条不变量**（`brk-not-monotonic`／`brk-first-not-after-start`／`brk-count-vs-content`）⇒ 拒时**表内不出现该段** ＋ 具名 `[LINEBREAK] rx=REJECT … out=UNWRITTEN`；收时**native 自算 `n_hard`**（从 `T-A69` 副本逐字符扫强制断行符）**＋ 读 `fl_line[]` 真断点**（`dcp_lim`）**＋ 逐断点 `cp = cp_first + dcp`** ＋ `seq` ＋ 三态 ＋ 具名 `rx=OK` 行。
3. **只读回读面**（导出 **22** 名）：`Feed`／`Count`／`Find`／`State`／`Seq`／`Para`／`CpFirst`／`CpLim`／`Cch`／`NHard`／`NBrk`／`Mono`／`FirstOk`／`CoverOk`／`DcpAt(k,i)`／`CpAt(k,i)`／`Info(k,i,field)`（三格可诚实字段；度量字段 ⇒ `-1`）／`Rx`／`RxGap`／`Mism`／`SelfCheck`／`SelftestMask`。
4. **两极化自检** `WpfLinuxWin32_PtsLineBreakSelfCheck()`：夹具段落由 `wpf_pts_sub_new` **真造**（⇒ `T-A71` 台账可收）、内容源由 `T-A69` 的 `…PtsTextSrcFeed` **真入站**、真排版行台账由本自检**当窗内夹具**直接置（＝真排版交回的同一 `fl_line[]` 形状）；跑 4 位（正极：`cp` 序列／骨架／两不变量逐格相符；反极必拒；**真断点非单调必红**；**跨域计数不变量破必红**）；收尾**真销毁 ＋ 复原全部可观测状态**（含 `g_pts_sub_*`／`g_pts_textsrc_*`／`g_pts_pc_*`／`g_pts_sub_claim_{ok,bad}`／`g_pts_hc_reading`）；表位不足／泄漏 ⇒ `-1`（**不算绿**）。
5. **Fake 路径**：**不在主链**；反腿**只在仓外副本**（`~/tA73-work/replica-native/`，见 §3.4）。

> 🔴 **无假值纪律（四条）**：① 失败路径**一字不写**（表内无该段）；② **不在链上／无内容源／无行台账** ⇒ 诚实拒绝（**不**用"收下即存"冒充"有断器"）；③ `EMPTY`（有台账但 0 断点）与 `NONE`（没台账）**不同形**；④ 断点不符 ⇒ **拒**（不截断、不静默）。

### 2.2 生成器：`build/PresentationFramework.Linux/reapply-patches.py`

| 项 | 内容 |
|---|---|
| `LBREAK_PROBE_FILE`／`LBREAK_PROBE_TEXT` | **新建件** `WpfLinuxLineBreakProbe.Linux.cs`：`Enabled`（闸 `WPF_LINEBREAK_FEED`，**缺省开**、**只有**显式 `"0"` 才关）／`FeedParagraph(parah)`（调 native ⇒ **立即回读**并逐格对拍（`state`／`mono`／`first`／`cover`／逐断点 `cp == cp_first + dcp`／最小骨架三格）⇒ 一行 `[LINEBREAK] mgd …`；native 拒绝时单列一行 `v=REJECT-LINE-BREAKER`） |
| `TPC_E_VV_REPL`（＋4 行） | 在 `TextParaClient` 的 `ValidateVisual` 内（既有 `T-A72` 喂料之后）加 `WpfLinuxLineBreakProbe.FeedParagraph(_paraHandle);` —— **纯增**、不改任何既有控制流 |
| `materialize_derived()` | 多写一个**非派生新建件**（`_write_atomic`：`temp + fsync + os.replace`） |
| `PATCH_C` | 多一行 `<Compile Include="…/WpfLinuxLineBreakProbe.Linux.cs" />` |

**幂等（现取）**：连跑两次，全部 `*.Linux.cs` ＋ `csproj` 的合并 `sha16` **两次同值** `d68f6ffc9b7b2ea6` ⇒ `GEN_IDEMPOTENT=YES`。

### 2.3 为什么落在**托管侧**（不是纯 native）

native **看不到"何时是这一段"**：段身份（`TextParaClient._paraHandle`）在**宿主**手上 ⇒ "对给定段触发"只能**由托管发起**；native 侧只做**认领校验 ＋ 内容源自算 ＋ 真断点对拍 ＋ 保管 ＋ 回读 ＋ 自检**（**不**自造一格）。而**真断点**本身来自托管（`pfnFormatLine` 真返回值，`T-A33` 回填源）—— 这正是"**托管已有真排版 ⇒ 它是真值源**"的落点。

---

## §3 成对读数

### 3.1 三腿（**只差权威 `.so`／`pf` 或一个 env**；同装置 `:231`；证据 `~/tA73-work/legs/`）

| 腿 | 权威 | env | 证据目录 | `LEGS_RUNNER` |
|---|---|---|---|---|
| `before` | `.so 630cefb6c7bdf0f0`／`pf 94a73efe3bc68808`（改前） | — | `~/tA73-work/legs/before/` | `PASS requested=2 obtained=2 refused=0` |
| `after` | `.so df27801beb222f05`／`pf 93f0368dac89f9c2`（改后） | — | `~/tA73-work/legs/after/` | `PASS requested=2 obtained=2 refused=0` |
| `rev`（**反极腿**） | 同 `after` | `WPF_LINEBREAK_FEED=0` | `~/tA73-work/legs/rev/` | `PASS requested=2 obtained=2 refused=0` |

同批工具（现取）：`runner_sha16=330a90f1f0ac28e4`／`session_sha16=f1a582d9ea9788c9`／`guard_sha16=ead59d60ccfc95b0`／`legs-to-env.py=ed290f41e5ae6432`；`device.txt`：`X_UP=yes display=:231`。

### 3.2 靶面成对（`grep -c` 现取，`app_g1.log`）

| 量 | `before`（改前） | `after`（改后／缺省） | `rev`（`FEED=0`） |
|---|---|---|---|
| `[LINEBREAK]` 行总数 | **0**（旧件无此面） | **50** | **0** |
| `[LINEBREAK] mgd`（托管对拍行） | **0** | **25** | **0** |
| `… mgd … mism=0` | — | **25/25** | — |
| `… mgd … mono=1 first=1 cover=1` | — | **25/25** | — |
| `… mgd … v=LINE-BREAKER-SET` | — | **50/50** | — |
| `… mgd … v=REJECT-LINE-BREAKER` | — | **0** | — |
| `[LINEBREAK] rx=OK`（native 收口行） | **0** | **25** | **0** |
| `[LINEBREAK] rx=REJECT` | **0** | **0** | **0** |
| 互异 `parah`（`[LINEBREAK]` 行内） | — | **25** | — |
| `[HC-UNHANDLED]` ／ `entry point named` ／ `failfast+unrec` | 0 ／ 0 ／ 0 | 0 ／ 0 ／ 0 | 0 ／ 0 ／ 0 |

**逐段断点现取（样例，逐字）**：

```
[LINEBREAK] mgd parah=0x62b74f1bf7e4 rc=0 slot=0 cp=[2,884) cch=882 n_brk=8 n_hard=8 mono=1 first=1 cover=1 dcp0=88 dcpN=956 seq=1 mism=0 v=LINE-BREAKER-SET
[LINEBREAK] mgd parah=0x62b74f1bd5d4 rc=0 slot=1 cp=[703,741) cch=38 n_brk=1 n_hard=0 mono=1 first=1 cover=1 dcp0=41 dcpN=41 seq=2 mism=0 v=LINE-BREAKER-SET
[LINEBREAK] mgd parah=0x62b74f1c3a14 rc=0 slot=2 cp=[754,767) cch=13 n_brk=1 n_hard=0 mono=1 first=1 cover=1 dcp0=16 dcpN=16 seq=3 mism=0 v=LINE-BREAKER-SET
```

```
[LINEBREAK] rx=OK slot=0 seq=1 parah=0x62b74f1bf7e4 cp=[2,884) cch=882 n_brk=8 n_hard=8 mono=1 first=1 cover=1 dcp0=88 dcpN=956 state=VALUE v=LINE-BREAKER-SET
[LINEBREAK] rx=OK slot=1 seq=2 parah=0x62b74f1bd5d4 cp=[703,741) cch=38 n_brk=1 n_hard=0 mono=1 first=1 cover=1 dcp0=41 dcpN=41 state=VALUE v=LINE-BREAKER-SET
```

**`n_brk`／`n_hard` 全谱（现取 `sort -u`）**：`n_brk=1/2/6/8`、`n_hard=0/2/8`（配对：`(1,0) (2,0) (6,0) (6,2) (8,8)`）；**`cch` 全谱**：`{9,12,13,16,22,38,40,568,588,882}`（与 `T-A69`／`T-A71` 的同一批 25 段**逐值相符**）。

### 3.3 探针（`dlopen` 直调；正极 ＝ 主链 `.so`）

> ⚠️ **口径（写死）**：本条的**正极**（"链上段 ＋ 有内容源 ＋ 有行台账"）**只能由 native 侧造**（可认领段＝`wpf_pts_sub_new` 的产物，探针无此导出）⇒ 正极由**自检**在 native 内用夹具完成；探针在外部做**负面面**（**不在链上／无内容源 ⇒ 必拒**）与**越界哨兵**。

```
EXPORTS present=13/13
== selftest ==
SELFTEST mask=0x0f
SELFTEST2 mask=0x0f（幂等：自检不改变可观测状态）
== negative (not in chain / no source) ==
FEED(null)=-10000
FEED(0x5a5a5a5a)=-10000
FIND(0x5a5a5a5a)=-1
== oob sentinels ==
OOB state=-1 nbrk=-1 nhard=-1 cpat=-1 dcp=-1 info=-1
== counters ==
COUNT=0 RX=0 RXGAP=2 MISMATCH=0
PROBE selftest_mask=0x0f rc=0   （MAIN_RC=0）
```

### 3.4 🔴 **反腿副本**（三条判据门在 `WPF_PTS_LB_FAKE` 上＝**静默半通**；该红必红）

`~/tA73-work/replica-native/bin/libwpfwin32.so` ＝ **`6857040231585236`**（仓外副本：把入站的**三条「断点不符」判据**（`brk-not-monotonic`／`brk-first-not-after-start`／`brk-count-vs-content`）门在编译期开关 `WPF_PTS_LB_FAKE` 上，其余逐字同 —— 即"**收下并声称成功却不校断点**"的静默半通形态；**主链一字未含该路径**）。

```
SELFTEST mask=0x03
SELFTEST2 mask=0x03
== negative == FEED(null)=-10000 FEED(0x5a5a5a5a)=-10000 FIND(0x5a5a5a5a)=-1
== counters == COUNT=0 RX=0 RXGAP=2 MISMATCH=0
PROBE selftest_mask=0x03 rc=1   （REPLICA_PROBE_RC=1）
```

⇒ **该红必红（两条独立证据）**：① **自检位** `0x0f→0x03`（**bit2「真断点非单调必红」** 与 **bit3「跨域计数不变量破必红」** 当场灭）；② **`PROBE_RC 0→1`**（判据当场红）。⇒ 本条的"**断点不符 ⇒ 该红必红**"**不是恒真断言**（它能把"收下却不校"照出来）。

### 3.5 反极腿（`WPF_LINEBREAK_FEED=0`；同一权威件）

| 量 | `after`（缺省） | `rev`（`=0`） |
|---|---|---|
| `[LINEBREAK]` 行总数 | **50**（25 native ＋ 25 mgd） | **0** |
| 本趟自定判据 `LINEBREAK_GUARD`（＝ `mgd>0 ∧ 全部 mism=0 ∧ 全部 mono=1 ∧ 全部 first=1 ∧ 全部 cover=1 ∧ 全部 rc=0 ∧ REJECT 0`；命令见 §4） | **PASS** | **FAIL**（无正读数 ⇒ 红） |
| `PTS_GUARD`／`PTS_COLORANCHOR`／`PTS_ENFE`／症状门 | `PASS legs=2/2`／`PASS hits=3`／`PASS total=0`／逐格 | **同**（如实记：本通道**观测用、不承重像素** ⇒ 这三门**不因它翻红**） |

> ⚠️ **如实披露（防读宽）**：本通道**不改变渲染**，所以反极腿的 `PTS_GUARD`／`PTS_COLORANCHOR` **两腿同值**（`colors 1220/636`、色锚不变）⇒ "断点不符 ⇒ 该红必红"**由本趟自定判据 ＋ §3.4 副本**承担，**不**由页门承担（页门在这条面**结构性不可分**）。

### 3.6 症状门 ＋ 帧面成对

| 量 | `before` | `after` | `rev` |
|---|---|---|---|
| `k24` | `alive=yes app_rc=143 magenta=0 colors=1220 ae=220019 ink=480000` | **同** | **同** |
| `k23` | `alive=yes app_rc=143 magenta=0 colors=636 ae=136292 ink=480000` | **同** | **同** |
| `PTS_GUARD` | `PASS legs=2/2` | **`PASS legs=2/2`** | **`PASS legs=2/2`** |
| `PTS_COLORANCHOR`（k24） | `PASS hits=3` | **`PASS hits=3`**（`GhostWhite=9794 Beige=910 DarkGreen=44 LightGoldenrodYellow=5830`） | **同** |
| `PTS_ENFE` | `PASS total=0` | `PASS total=0` | `PASS total=0` |

| 对 | `boot` | `k23` | `k24` | `last` |
|---|---|---|---|---|
| `fr_sha(before)` | `b21eb530afd3c66c` | `10d0b9d54e649c10` | `0bdb2dfd05952bc9` | `10d0b9d54e649c10` |
| `fr_sha(after)` | `b21eb530afd3c66c` | `10d0b9d54e649c10` | `0bdb2dfd05952bc9` | `10d0b9d54e649c10` |
| `fr_sha(rev)` | `b21eb530afd3c66c` | `10d0b9d54e649c10` | `0bdb2dfd05952bc9` | `10d0b9d54e649c10` |
| `AE(before,after)`／`AE(after,rev)` | **0／0** | **0／0** | **0／0** | **0／0** |

⇒ **零回归**（`compare -metric AE` 逐帧实测 0）。

---

## §4 门禁（现取；`rc` 一律取自 `>out 2>err; echo $?` 形态）

| 门 | 读数 | rc |
|---|---|---|
| `nm==exports` | `nm -D --defined-only` ＝ **846** ＝ `exports.txt` 行数；**逐名 `diff` 零差异**；**新增 22 名、无消失**（`WpfLinuxWin32_PtsLineBreak{Feed,Count,Find,State,Seq,Para,CpFirst,CpLim,Cch,NHard,NBrk,Mono,FirstOk,CoverOk,DcpAt,CpAt,Info,Rx,RxGap,Mism,SelfCheck,SelftestMask}`） | 0 |
| `PTSGAP` | `PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=df27801beb222f05 exports=846`（`tool/ops/impl` **未动**；`PTSGAP_HISTORICAL=n=11`；`PTSGAP_CITED=PASS refs=1`；`PTSGAP_FRONTIER_STATE=NAMED frontier=FsQueryTextDetails`） | 0 |
| `DEFREG` | `PASS declared=225 route_ids=225`；`DECLDRIFT=0 keys=-` | 0 |
| `REPORTID` | `PASS files=348 ids=2257 declared=225`（本件落盘后 `347→348`，`+1` 即本件） | 0 |
| `HANDOFF_MV` | `PASS cells=9 equal=8 manual=1 mismatch=0`（已按第 `28` 条契约在 `HANDOFF-NEXT.md` 文件尾**只增**追写机器值契约行） | 0 |
| `GEN_IDEMPOTENT` | 连跑两次：全部 `*.Linux.cs` ＋ `csproj` 的合并 `sha16` ＝ `d68f6ffc9b7b2ea6`（两次同值） | 0 |
| `PTS-PAGES`（腿产证据） | `PTS_GUARD=PASS legs=2/2`／`PTS_COLORANCHOR=PASS k=24 hits=3`／`PTS_ENFE=PASS total=0`（三条腿各一次，逐腿同值；`PTS_N1_GATE=PASS phase=realized positive=differ(via=compare)`） | 0 |
| **本趟自定判据** `LINEBREAK_GUARD` | `mgd>0 ∧ 全部 rc=0 ∧ 全部 mism=0 ∧ 全部 mono=1 ∧ 全部 first=1 ∧ 全部 cover=1 ∧ REJECT 0`（命令：`grep -a '\[LINEBREAK\] mgd' <leg>/app_g1.log` 取计数）；`after` ⇒ **PASS**（25/25/25/25/25/25/25）；`rev` ⇒ **FAIL**（0 条正读数） | 0／1 |

---

## §5 逐件 `sha16`（现取）

| 件 | 改前 | 改后 |
|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `ab4b685704b53ed3`（817199 B／11087 行） | **`31964874821daae4`**（842641 B／11458 行） |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so`（**非仓内件**） | `630cefb6c7bdf0f0`（544008 B） | **`df27801beb222f05`**（553936 B） |
| `src/WpfGfx.Linux.Native/bin/exports.txt`（**非仓内件**） | `e5675ec32f7323df`（824 行） | **`83b60726bbc2486e`**（846 行） |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `9a2212296af5ea24`（674 行） | **`b735620eacf6fa4a`**（705 行） |
| `build/PresentationFramework.Linux/reapply-patches.py`（生成器） | `80c84ee298ca1b6d`（187697 B） | **`bdc71ac713a9a925`**（197919 B／3265 行） |
| `…/TextParaClient.Linux.cs`（重产件） | `ac37879992d9572f`（212650 B／4333 行） | **`1a70c5168393b0ea`**（212968 B／4337 行；＋4 行：触发调用 ＋ 注释） |
| `…/PresentationFramework.Linux.csproj`（重产件） | `74f7401735efe70b`（1589 行） | **`5b05e4fe2556f794`**（1591 行；＋2 行：新件 `<Compile Include>`） |
| `…/WpfLinuxLineBreakProbe.Linux.cs`（重产件 · **本趟新建**） | — | **`519fd5889d979537`**（8221 B／142 行） |
| `build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll`（**非仓内件**） | `94a73efe3bc68808`（6156800 B） | **`93f0368dac89f9c2`**（6159360 B） |
| `docs/ROUTES.md` | `4e0239f346632268`（1133 行） | **`b304c75bc62104b3`**（1134 行） |
| `build/MilBridge/HANDOFF-NEXT.md` | `59892f54ad107b0b`（774 行） | **`35d378a099fc9589`**（776 行；文件尾**只增**两段机器值契约行，`inputs_fp 66a10171…→0d9ab995…`） |
| `docs/WAVE66-PREREGISTRATION.md`（**冻证据**） | `bf6b683d94549087` | **未变**（`bf6b683d94549087`） |

> ⚠️ 生成器**重产件**里 `PtsCache.Linux.cs`／`FlowDocumentView.Linux.cs`／`FlowDocumentPage.Linux.cs`／`PtsPage.Linux.cs`／`PtsHelper.Linux.cs`／`FigureParaClient.Linux.cs`／`ContainerParaClient.Linux.cs`／`FlowDocumentFormatter.Linux.cs`／`FlowDocumentPaginator.Linux.cs`／`WpfLinuxChainProbe.Linux.cs`／`WpfLinuxTextSrcProbe.Linux.cs`／`WpfLinuxCpDcpMapProbe.Linux.cs`／`WpfLinuxTextParaChainProbe.Linux.cs`／`WpfLinuxLsSessionProbe.Linux.cs` **逐字节未变**（现取：本趟只有 `TextParaClient.Linux.cs`／`csproj` 两件变 ＋ `WpfLinuxLineBreakProbe.Linux.cs` 一件新）。

---

## §6 诚实边界（**防读宽**，逐条）／具名 `NOINFO`

1. 🔴 **本条只判"断点集合可现取 ∧ 只按可诚实规则自算 ∧ 与托管真断点在两条不变量上逐段对拍 ∧ 可两极化"**；**不**判"排版前进"、**不**判"`W` 解除"（三腿四帧逐字节同 ⇒ **零像素位移**）。
2. 🔴 **"断点"不是"本侧断出来的"**：断点 `dcp` 由**托管真排版**产出（`pfnFormatLine` 真返回值）；`cp_first` 由 `T-A69` 给出；本侧**只收／只认领／只对拍／只回读**（`P1-layout-content-criteria.md:146` 的 `P9` 边界仍成立）。**本侧唯一自算**的是**内容源里的强制断行序列计数**（不依赖度量）。
3. 🔴 **"域不同"（本件核心划界）**：内容源是**文本域**，`fl_line[]` 的 `dcp` 是**排版域**（含元素边界符号）⇒ **不可逐点换算**（现取：`cch=38` 而 `dcpN=41`）⇒ 本块**只做跨域计数不变量 ＋ 域内自洽**，**不**跨域对点、**不**伪造映射（具名 `NOINFO-linebreak-domain-mismatch`）。
4. 🔴 **"最小 `LsLInfo` 骨架"的度量字段全不给**：`cpFirstVis`／`cpLim`／`fFirstLineInPara` 三格可诚实推出；**度量字段**（ascent/descent/vaAdvance…）本侧**无源** ⇒ `Info(k,i,3)` 恒 `-1`（**不伪造度量**，`P3`／`P8`）。
5. 🔴 **"软断行"本侧推不出**：`n_brk - n_hard` 的差（软断行条数）**本侧不判**（无度量源）⇒ 如实声明，不把它读成"断器不全"（那是**结构性**的：软断行按宽度换行，需 `GetRunCharWidths`／度量）。
6. 🔴 **`PTS_GUARD`／`PTS_COLORANCHOR`／`PTS_ENFE` 在本条面上不可分**：本通道**观测用**、**不承重像素** ⇒ 反极腿这三门**同值**；"断点不符 ⇒ 该红必红"由**自定判据 ＋ §3.4 副本**承担。
7. 🔴 **有界性（如实记）**：在册条数 ≤ `8`、逐段断点 ≤ `32`（真排版行数上界 `WPF_PTS_FL_MAXLINE`）；**表满 ⇒ 有界复用最旧槽**（具名行带 `slot=`）。本趟 25 段**落在 8 槽上轮转**（`slot=0..7` 循环）⇒ 回读面是"**最近 8 段**"视图，**不是**全量台账（**明示，防读成全量**）。
8. 🔴 **触发粒度**：每条腿只对**首次**遇到的 `_paraHandle` 触发一次（`_done` 去重；`MaxFeeds=64`）⇒ 每段只记一行；25 段对应**同批 25 段**（与 `T-A69`／`T-A71`／`T-A72` 的 `parah` 集合**逐值可对**）。
9. **具名 `NOINFO`（逐条给"消掉条件"）**：
   - **`NOINFO-linebreak-domain-mismatch`**：内容源（文本域）↔ 真断点（排版域）**不可逐点换算**。**消掉条件**：宿主给出 `cp↔字符` 与元素边界符号的**全映射**（本侧**只校不算**），或本侧接上度量源做真断行。
   - **`NOINFO-linebreak-soft-breaks`**：**软断行**（按宽度换行）本侧推不出。**消掉条件**：接 `LS-CB-M1` 的 `GetRunTextMetrics`／`GetRunCharWidths`（度量源，越级）。
   - **`NOINFO-linebreak-cross-page`**：粒度 ＝ **单段落**（承契约 `:100`）；"跨页/整页"结论**不由本条宣布**。
   - **`NOINFO-linebreak-ls-window`**：本趟触发点是 `TextParaClient.ValidateVisual`（**托管方法窗**），**不是** LS 的 `LoCreateLine` 会话窗。**消掉条件**：本侧成为重入方并驱动 `Lo*`（`C2` 的 `plsrun` 那一半）。
10. **未跑整趟 `verify-all`**（照派单）；本节所有"不得读成绿"的口径照在册红榜 `P1–P10`。

---

## §7 遗留（下一增量具名靶）

- **`W` 余项**：`C2`（`plsrun` 那一半）／`PRECOND-NEW-CALLBACK-FACE`（度量/回调面）**未解除**（`PRECOND-NO-LINE-BREAKER` 的**字面**已由本条推进为"**有可现取的真读数**"：断点 `cp` 序列可寻址 ∧ 两条不变量逐段对拍有牙 ∧ 可两极化）；本件**不**授权任何判据放宽。
- **最近的一格（可选）**：把"**最近 8 段**"的有界视图升为"按证据序号可追"（同 `T-A69`／`T-A72` 的 `ev_seq` 建议）。
- **越级项（须队长裁定）**：**度量源**（`LS-CB-M1` 的 `GetRunTextMetrics`／`GetRunCharWidths`）—— 它是判据 `:100` 的六条合取之 ④（行盒）的真前置，也是"断点由**本侧**断出（含软断行）"的唯一通路；本条**未**触碰。

---

`P1-TAIL2-LINEBREAK 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 0d951a1d9cc640f7（末行＝本行）`

# `P1-tail2` · `T-A70` · **`cp↔dcp` 偏移由宿主给定（契约 `C4`；本侧只校不算）**（`W` 合取⑤ `C4`；`TASK-0307` 增量）—— 实现报告

**判决**：把契约 `C4`（`build/MilBridge/P1-ls-provenance-contract.md:72`：「`cp ↔ dcp` 偏移｜**宿主**｜须**新立**｜本侧**只能"复算校验"，不能自算**」）落地成 native 侧一条**偏移映射入站通道 ＋ 校验器（只校不算）**：**托管侧**（生成器重产件 `WpfLinuxCpDcpMapProbe.Linux.cs` ＋ `TextParaClient.Linux.cs` 的 `ValidateVisual` 一处调用）在**同一次调用窗内**把**该段落的 `(cp,dcp)` 偏移映射样本对**交给 native；native 在窗内**值拷贝**并**当场校验**（**单调**／**端点**／**双射**／**偏移守恒**／**越界**），**任一不符 ⇒ 诚实拒绝**（表内不出现该段＋具名 `[CPDCMAP] rx=REJECT`）；随后托管**回读 native 样本副本并逐点对拍**。**真腿现取（`after`）**：`[CPDCMAP] mgd … mism=0 pair_match=1 off=0 state=2 v=CP-DCP-MAP-INBOUND` **×25**（`n ∈ {9,12,13,16}`、`cp_base 1…1531`、25 个**互异** `parah`）＋ native `[CPDCMAP] rx=OK …` **×25**。**两极化**：探针 `[CPDCMAP-SELFTEST] mask=0x0f`（4/4）；**反腿副本**（结构校验被门在 `WPF_PTS_CPDCMAP_FAKE` 上＝静默半通）⇒ `mask=0x07`／`REVERSE order/dup/back/off/end=0`／`find(rejected)=1`／`PROBE_RC=1`（**该红必红**）；**反极腿**（`WPF_CPDCMAP_FEED=0`）⇒ `[CPDCMAP]` 行 **0 条**。**零回归**（改前/改后/反极三腿四帧**逐字节同**；`PTS_GUARD=PASS`／`PTS_COLORANCHOR=PASS hits=3`）。**导出面**：`exports 763→778`（逐名 **+15**、**无消失**），`nm==exports`；`PTSGAP`／`DEFREG`／`REPORTID` rc=0。🔴 **如实划界（本件的核心判决）**：**只校 ≠ 对真值** —— 本条校验的是**自洽性**（单调／端点／双射／守恒／越界），**不是**与外部 LS 真值对拍；契约 §5 反腿 (a)"偏移错一"须**外部 LS 真值** ⇒ 今天**不跑**（随"内容层那一波"），本趟两极化由**乱序／非双射**承担；本移植链上**无 LS 隐藏文本** ⇒ 显示偏移**真值 ＝ 0**（**如实声明，不伪造非零**）；`W` 整体仍**未解除**。

- **读时**：`2026-10-01T23:3x–2026-10-02T00:2x+0800`（本席现取；各条另注）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`（**未 `git add/commit/push`**）；开工 `HEAD=6c95cf4`（`T-A69`）。
- **改前件备份（仓外 `~/tA70-work/bak/`，`cp -p`，取在**任何写之前**）**：`win32_pts.c`（`9898ddf503e101bd`／751361 B）／`bin/libwpfwin32.so`（`a5e9e090a6a64273`／514512 B）／`bin/exports.txt`（`b18279c21205a6f3`／763 行）／`tools/pts-gap-decl.txt`（`be0bfd844be2f4b2`）／`build/PresentationFramework.Linux/reapply-patches.py`（`fd06cd5cda068787`）／其重产件（`bak/generated/`：`WpfLinuxTextSrcProbe.Linux.cs d0d77fc5a7a822dc`／`WpfLinuxChainProbe.Linux.cs 856d68514ff328d5`／`TextParaClient.Linux.cs 68d73bd2e8988456`／`PresentationFramework.Linux.csproj b2497e058fafb3bc`）／`PresentationFramework.dll`（`0e9d02917de9379b`）／`docs/ROUTES.md`（`97cd86579bd2b224`）／`build/MilBridge/HANDOFF-NEXT.md`。
- **写域（逐件）**：`src/WpfGfx.Linux.Native/src/win32_pts.c`（**加一段 `T-A70` 块**：偏移映射入站通道 ＋ 只校不算校验器 ＋ 逐条只读回读面 ＋ 两极化自检）／`src/WpfGfx.Linux.Native/bin/exports.txt`（**构建重产**，非手改）／`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（DECL 行 `so16`／`exports` 跟权威件换 ＋ 只增一段 `T-A70` 重锚）／**生成器** `build/PresentationFramework.Linux/reapply-patches.py`（新增 `CPDCMAP_PROBE_FILE`／`CPDCMAP_PROBE_TEXT` ＋ `TPC_E_VV_REPL` 一处调用 ＋ `materialize_derived()` 写新件 ＋ `PATCH_C` 一行 `<Compile Include>`）／**其重产件**（`WpfLinuxCpDcpMapProbe.Linux.cs` **新建件**、`TextParaClient.Linux.cs`、`PresentationFramework.Linux.csproj`）／**复述位现值位**（`docs/ROUTES.md` `TASK-0307` 行加一条 dated 结账；`build/MilBridge/HANDOFF-NEXT.md` 文件尾机器值契约追写）／**新建载体** 本件。
- **未改**（如实体例）：`docs/WAVE66-PREREGISTRATION.md`（冻证据 `w66pre16=bf6b683d94549087` 未动）；`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`src/WpfGfx.Linux.Native/src/win32_classification.c`（本趟**未移动**它们所持的 `tool/ops/impl` 三格 ⇒ `PTSGAP` 判据**要求**它们**不动**，见 §4）；`bin/libwpfwin32.so`／`bin/exports.txt`／`build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` 属**构建产物**（非仓内件）。
- **黑名单遵守**：未动 `build/MilBridge/tools/**`（**只读跑**判据件）／`verify-all.sh`／`build/close-wave.sh`／`build/shims/**`／`upstream/**`（只读）；**未跑**整趟 `verify-all`；未改相位位；未 `git add/commit/push`。
- **重活**：**1 趟 native 构建**（含 `--symbols`）＋ **1 趟托管构建**（`0 警告 0 错误`，`25.6 s`）＋ **1 趟跑器**（`before`／`after`／`rev`，共 **6 条腿**）＋ **1 趟仓外副本 native 构建**（反腿），全走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- <cmd>`（逐趟 `HEAVYSLOT=ACQUIRED/MEMOK/RELEASED rc=0`）；进程只按 PID；显示位只用跑器自分配的号（`DISPLAY_PICK :231`）；禁 `sleep` 轮询；写前 `cp -p`；`temp+rename`（生成器 `_write_atomic`）；模式守恒。
- **口径**：一切读数**本席现取**（`sha256sum`／`nm -D --defined-only`／`diff`／`grep -c`／`gcc` 编译的 `dlopen` 探针 `~/tA70-work/probe`／只读跑 `bash build/MilBridge/tools/{pts-gap-count-check,pts-pages-guard,defect-registry-check,report-id-domain-check,handoff-machine-values-check}.sh`）。凡引他件处一并标注。

---

## §0 结论速览（自包含）

1. ✅ **`C4` 已按契约落地（现取）**：native 侧新增**偏移映射入站通道 ＋ 只校不算校验器 ＋ 逐条只读回读面 ＋ 两极化自检**（`WpfLinuxWin32_PtsCpDcpMap{Feed,Count,Find,State,NPoints,CpBase,Offset,Seq,CpAt,DcpAt,Rx,RxGap,Empty,SelfCheck,SelftestMask}`，**15 名**）；**托管侧**在 `TextParaClient.ValidateVisual` 内把**段落的 `(cp,dcp)` 样本对**在**同一窗内**交给 native。⇒ 契约 `C4` 的"**由宿主给定并留痕**"（`:72`／§6 ③）**满足**。
2. ✅ **宿主给定偏移现取（逐条 ＋ 逐点对拍）**：`after` 腿 `[CPDCMAP] mgd …` **×25**（`mism=0 pair_match=1`；`n ∈ {9,12,13,16}`；`cp_base ∈ 1…1531`；`off=0`；**25 个互异 `parah`**）＋ native `[CPDCMAP] rx=OK …` ×25 ⇒ **逐点对拍零失配**；`before`／`rev` **0 条**。
3. ✅ **两极化（该红必红）**：① 探针 `[CPDCMAP-SELFTEST] mask=0x0f`（4/4：合法映射／`EMPTY≠NONE`／反极必拒／**乱序＆非双射必红**）；② **反腿副本**（`~/tA70-work/replica.so 6b28f308bb8d4d24`，把结构校验门在 `WPF_PTS_CPDCMAP_FAKE` 上＝"收下却不校"的**静默半通**形态）⇒ `mask=0x07`、`REVERSE order/dup/back/off/end=0`、`find(rejected)=1`、`PROBE_RC=1` ⇒ **判据当场红**；③ **反极腿**（`WPF_CPDCMAP_FEED=0`，同一权威件）⇒ `[CPDCMAP]` 行 **0 条**。
4. ✅ **零回归**：`.so a5e9e090a6a64273（改前）→ c5acc47490098ff0（改后）`／`pf 0e9d02917de9379b → 75f1a79441d01b16`；三腿（`before`／`after`／`rev`）四帧**逐字节相同**（`boot b21eb530afd3c66c`／`k23 10d0b9d54e649c10`／`k24 0bdb2dfd05952bc9`／`last 10d0b9d54e649c10`）、症状门逐格同；`PTS_GUARD=PASS legs=2/2`／`PTS_COLORANCHOR=PASS k=24 hits=3` **未回退**。
5. ✅ **门禁（现取）**：`nm -D --defined-only` ＝ `exports.txt` ＝ **778**（逐名 `diff` 零差异；**+15 无消失**）；`PTSGAP=PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=c5acc47490098ff0 exports=778`（rc=0）；`DEFREG=PASS declared=225 route_ids=225`（rc=0）；`REPORTID=PASS`（rc=0）；`HANDOFF_MV` 按第 `28` 条契约追写后 PASS。
6. 🔴 **如实划界（本件的核心判决）**：本条**只**判「**偏移映射由宿主给定 ∧ 本侧只校不算 ∧ 可逐条现取 ∧ 可与托管真值逐点对拍 ∧ 可两极化**」。它**不**判「`W` 解除」—— `C2`（`plsrun` 那一半）／`PRECOND-NO-LINE-BREAKER`／`PRECOND-NO-TEXT-PARA-IN-CHAIN`／`PRECOND-LS-SESSION-DRIVER` **仍在册**；**只校 ≠ 对真值**（契约 §5 两条必红反腿 (a)(b) **今日仍不可执行**）。

---

## §1 `C4`／「宿主给定偏移」的**准入判据**（现取：件:行 ＋ 满足／不满足）

> **判据一律逐字引自**已登载的判据件（件:行）；行号只保证本次有效（内容锚原文一并给）。

### 1.1 在册出处（逐字）

| 角色 | 件:行 | 现取原文（要点） |
|---|---|---|
| **契约本体（本条的靶）** | `build/MilBridge/P1-ls-provenance-contract.md:72` | 「**`C4`**｜`cp ↔ dcp` 偏移｜**宿主**（只能宿主，`t190` 已判本侧无 `dcp`）｜❌ **不存在**：全仓无填点 ⇒ **须新立** … ｜⚠️ **只能"复算校验"，不能自算**：宿主给出偏移后，本侧可校验**自洽性**（同段落内加减守恒、不同段落偏移不得混用、`dcp` 不越界），**不得**自行推导」 |
| **`W` 合取⑤** | `build/MilBridge/P1-tail2-dingrecon.md:95`（§3.2） | 「**`cp↔dcp` 偏移由宿主给定**（本侧**只校不算**）—— 契约 `C4`（`P1-ls-provenance-contract.md:72`）」 |
| **验收面 ③** | `P1-ls-provenance-contract.md:93`（§6 `acceptance`） | 「③ **`C4` 由宿主给定**并**留痕**（本侧**不得**自算）」 |
| **两条必红反腿（标"随那一波"）** | `P1-ls-provenance-contract.md:80-81` | 「**(a)** 偏移错一 … 校验器**必须报红** … **若 ±1 也判绿 ⇒ 判据无判别力 ⇒ 该判据作废**」；「**(b)** 跨段落复用同一 `plsrun` 表 ⇒ **必须报红**」；「❌ **不能**（无 LS 会话、本侧无 `dcp` 值）⇒ 标**"随内容层那一波"**」 |
| **`outOfScope`（本侧不得自算）** | `P1-ls-provenance-contract.md:99` | 「任何由本侧自算 `dcp`／`plsrun` 的做法」 |
| **源在谁手上（`P9` 边界）** | `P1-layout-content-criteria.md:146` | 「**源在宿主侧**（托管 `TextContainer`/`TextFormatter`……）……本件只判"**取它要开新面**"」 |

⇒ **本条把「宿主给定偏移（只校不算）」判据化（写死）为五条合取**：**(a)** 有一条真入站通道（宿主把 `(cp,dcp)` 样本对交进本侧）；**(b)** 本侧**只校不算**（校验自洽性，不由 `cp` 推 `dcp`）；**(c)** 逐条可现取（`off`／`npts`／`cp_base`）**且与托管真值逐点对拍相符**；**(d)** 两极化：**乱序／非双射 ⇒ 该红必红**，`WPF_CPDCMAP_FEED=0` ⇒ 0 条；**(e)** 留痕（`[CPDCMAP]` 具名行）。

### 1.2 逐条现取（满足／不满足）

| # | 判据 | 现取读数（`after` 腿／探针） | 判定 |
|---|---|---|---|
| **(a) 入站通道** | 宿主把 `(cp,dcp)` 样本对交进 native ⇒ `[CPDCMAP] rx=OK` 计数 `0→25`；`before` 腿 **0** | ✅ **满足**（`wsrc/win32_pts.c` `WpfLinuxWin32_PtsCpDcpMapFeed` ＋ 生成件 `WpfLinuxCpDcpMapProbe.FeedParagraph`；调用点 `TextParaClient.Linux.cs` `ValidateVisual`） |
| **(b) 只校不算** | native **只核**单调／端点／双射／守恒／越界；`off` **取自宿主样本**（`dcp[0]-cp[0]`），本侧**不**由 `cp` 推 `dcp` | ✅ **满足**（反腿：乱序/非双射/守恒破/端点不符 ⇒ 拒；见 §3） |
| **(c) 逐条可读 ＋ 逐点对拍** | `Find/NPoints/CpBase/Offset/Seq/CpAt/DcpAt` 逐条现取；`mgd` 行 `mism=0 pair_match=1` **25/25** | ✅ **满足** |
| **(d) 两极化** | 探针 `SELFTEST mask=0x0f`；反腿副本 `mask=0x07`／`REVERSE …=0`／`rc=1`；反极腿 `[CPDCMAP]` 行 `25→0` | ✅ **满足** |
| **(e) 留痕** | `[CPDCMAP] rx=OK slot=… seq=… parah=… cp_base=… npts=… off=… dcp0=… dcpN=… state=VALUE v=CP-DCP-MAP-INBOUND` ×25 | ✅ **满足** |

### 1.3 🔴 「满足」的**射程**（写死，防读宽）

1. **"自洽性"这一半满足，"对真值"那一半不满足**：本趟校验的是**映射自身的结构自洽**（单调／端点／双射／守恒／越界）；**不是**与外部 LS 真值（真 LS 会话里的 `dcp`）对拍。契约 §5 反腿 (a)"偏移错一"**须外部真值** ⇒ 今天**不跑**（承 `P1-ls-provenance-contract.md:80`），标**"随内容层那一波"**。
2. **"只校不算"＝不越权**：`off` **完全来自宿主给的样本**（`dcp[i]-cp[i]`，本侧只**核其守恒**）；native **无**任何由 `cp` 推 `dcp` 的分支（契约 `outOfScope`，`:99`）。
3. **本移植链上偏移真值 ＝ 0**（写死，防读成"伪造"）：本移植**绕过 LS 造型**（`build/PresentationCore.Linux/TextFormatterImp.Linux.cs`），链上**无 LS 隐藏文本** ⇒ 该层的**显示偏移真值本就 ＝ 0**（`dcp == cp`）；托管**如实声明**、**不伪造**非零偏移。⚠️ 这**不是**"把 `±1` 判绿"—— 它只是"**本层给定值恰为 0**"，**不构成**对 ±1 反腿的判别力（该反腿须外部真值，见上条）。
4. **"同一窗内"的语义（写死）**：入站与对拍发生在**托管方法的一次调用窗内**（`TextParaClient.ValidateVisual` 内：喂料 ⇒ 立刻回读 ⇒ 对拍）；native 对**入参指针只在窗口内**逐点值拷贝（指针出窗即不可用）。⚠️ 这**不是** LS 的 `LoCreateLine` 会话窗 —— 那一格仍缺（`PRECOND-LS-SESSION-DRIVER`）。

---

## §2 改动（逐处）

### 2.1 native：`src/WpfGfx.Linux.Native/src/win32_pts.c`（新增一段 `T-A70` 块）

1. **常量／结构**：`WPF_PTS_CPDCMAP_{MAX=8,PT_MAX=64,ST_NONE/EMPTY/VALUE,MAGIC}` ＋ `wpf_pts_cpdc`（`parah`／`cp_base`／`npts`／`offset`／`state`／`seq`／`cp[PT_MAX]`／`dcp[PT_MAX]`）＋ 6 个计数（`n`／`seq`／`rx`／`gap`／`empty`／`rr`）。
2. **入站（唯一收口）** `WpfLinuxWin32_PtsCpDcpMapFeed(parah, cp_base, n, cp[], dcp[])`：先过**四条拒面**（`null-para`／`negative-n`／`npts-over-bound`／`null-cp`／`null-dcp`）⇒ 再**结构校验**（越界 `cp-negative`／`dcp-negative`；**端点** `cp[0]!=cp_base`；**单调（严格）＋双射** `nonmonotonic-cp`／`nonmonotonic-dcp`；**守恒** `offset-not-constant`）；**任一不符 ⇒ 表内不出现该段** ＋ 具名 `[CPDCMAP] rx=REJECT reason=… out=UNWRITTEN bytes=0`；收时**窗内值拷贝** ＋ `offset=dcp[0]-cp[0]` ＋ `seq` ＋ 三态 ＋ 具名 `[CPDCMAP] rx=OK …`。
3. **只读回读面**（导出）：`Count`／`Find`／`State`／`NPoints`／`CpBase`／`Offset`／`Seq`／`CpAt(k,i)`／`DcpAt(k,i)`（越界 ⇒ `-1`，合法样本值域 ≥ 0）／`Rx`／`RxGap`／`Empty`。
4. **两极化自检** `WpfLinuxWin32_PtsCpDcpMapSelfCheck()`：夹具（文件级静态身份 ⇒ 地址稳定互异）跑 4 位（**合法映射（含 `off≠0` 例）／`EMPTY≠NONE`／反极必拒／乱序＆非双射＆守恒破＆端点不符必红**）；收尾**真销毁 ＋ 复原全部可观测状态**；表位不足／泄漏 ⇒ `-1`（**不算绿**）。
5. **Fake 路径**：**不在主链**；反腿**只在仓外副本**（`~/tA70-work/replica-native/`，见 §3.4）。

> 🔴 **无假值纪律（四条）**：① 失败路径**一字不写**（表内无该段）；② 无源 ⇒ `Find==-1`（**不**用零值／空表冒充"有映射"）；③ `npts==0`（`EMPTY`）与"根本没入站"（`NONE`）**不同形**；④ 越界 ⇒ **拒**（不截断、不静默）。

### 2.2 生成器：`build/PresentationFramework.Linux/reapply-patches.py`

| 项 | 内容 |
|---|---|
| `CPDCMAP_PROBE_FILE`／`CPDCMAP_PROBE_TEXT` | **新建件** `WpfLinuxCpDcpMapProbe.Linux.cs`：`Enabled`（闸 `WPF_CPDCMAP_FEED`，**缺省开**、**只有**显式 `"0"` 才关）／`FeedParagraph(parah, para)`（取 `ParagraphStartCharacterPosition` 作 `cp_base` ＋ 连续 `min(len,16)` 点 `(cp,dcp)`（本层 `dcp==cp`）⇒ 调 native ⇒ **立即回读 native 副本**并**逐点对拍** ⇒ 一行 `[CPDCMAP] mgd …`） |
| `TPC_E_VV_REPL`（＋4 行） | 在 `TextParaClient` 的 `ValidateVisual` 内（既有 `T-A69` 喂料之后）加 `WpfLinuxCpDcpMapProbe.FeedParagraph(_paraHandle, Paragraph);` —— **纯增**、不改任何既有控制流 |
| `materialize_derived()` | 多写一个**非派生新建件**（`_write_atomic`：`temp + fsync + os.replace`） |
| `PATCH_C` | 多一行 `<Compile Include="…/WpfLinuxCpDcpMapProbe.Linux.cs" />` |

**幂等（现取）**：连跑两次，全部 `*.Linux.cs` 的合并 `sha16` **两次同值** `ca375306b3dcb629` ⇒ `GEN_IDEMPOTENT=YES`。

### 2.3 为什么落在**托管侧**（不是纯 native）

契约 `C4` 明写"**只能宿主**"（本侧无 `dcp`）：偏移的**作者是宿主**（托管 `TextParaClient` 持有 `ParagraphStartCharacterPosition` 与显示位置样本）⇒ "把该段落的偏移映射交出来"只能**由托管发起**；native 侧只做**入站 ＋ 校验（只校不算） ＋ 保管 ＋ 回读 ＋ 自检**（**不**自造一点映射）。

---

## §3 成对读数

### 3.1 三腿（**只差权威 `.so`／`pf` 或一个 env**；同装置 `:231`；证据 `~/tA70-work/legs/`）

| 腿 | 权威 | env | 证据目录 | `LEGS_RUNNER` |
|---|---|---|---|---|
| `before` | `.so a5e9e090a6a64273`／`pf 0e9d02917de9379b`（改前） | — | `~/tA70-work/legs/before/` | `PASS requested=2 obtained=2 refused=0` |
| `after` | `.so c5acc47490098ff0`／`pf 75f1a79441d01b16`（改后） | — | `~/tA70-work/legs/after/` | `PASS requested=2 obtained=2 refused=0` |
| `rev`（**反极腿**） | 同 `after` | `WPF_CPDCMAP_FEED=0` | `~/tA70-work/legs/rev/` | `PASS requested=2 obtained=2 refused=0` |

同批工具（现取）：`runner_sha16=330a90f1f0ac28e4`／`session_sha16=f1a582d9ea9788c9`／`guard_sha16=ead59d60ccfc95b0`／`legs-to-env.py=ed290f41e5ae6432`。

### 3.2 靶面成对（`grep -c` 现取，`app_g1.log`）

| 量 | `before`（改前） | `after`（改后／缺省） | `rev`（`FEED=0`） |
|---|---|---|---|
| `[CPDCMAP] mgd`（托管对拍行） | **0**（旧件无此面） | **25** | **0** |
| `… mgd … mism=0` | — | **25/25** | — |
| `… mgd … pair_match=1` | — | **25/25** | — |
| `… mgd … v=NO-SOURCE` | — | **0** | — |
| `[CPDCMAP] rx=OK`（native 入站行） | **0** | **25** | **0** |
| `[CPDCMAP] rx=REJECT` | **0** | **0** | **0** |
| 互异 `parah`（mgd 行内） | — | **25** | — |
| `[HC-UNHANDLED]` ／ `entry point named` ／ `failfast+unrec` | 0 ／ 0 ／ 0 | 0 ／ 0 ／ 0 | 0 ／ 0 ／ 0 |

**逐段偏移映射现取（样例，逐字）**：

```
[CPDCMAP] mgd parah=0x5b40f77e24b4 cp_base=2 n=16 rc=0 slot=0 mism=0 pair_match=1 off=0 state=2 v=CP-DCP-MAP-INBOUND
[CPDCMAP] mgd parah=0x5b40f3074be4 cp_base=703 n=16 rc=0 slot=1 mism=0 pair_match=1 off=0 state=2 v=CP-DCP-MAP-INBOUND
[CPDCMAP] mgd parah=0x5b40f3077824 cp_base=754 n=13 rc=0 slot=2 mism=0 pair_match=1 off=0 state=2 v=CP-DCP-MAP-INBOUND
```

```
[CPDCMAP] rx=OK slot=0 seq=1 parah=0x5b40f77e24b4 cp_base=2 npts=16 off=0 dcp0=2 dcpN=17 state=VALUE v=CP-DCP-MAP-INBOUND
[CPDCMAP] rx=OK slot=1 seq=2 parah=0x5b40f3074be4 cp_base=703 npts=16 off=0 dcp0=703 dcpN=718 state=VALUE v=CP-DCP-MAP-INBOUND
```

**`n` 全谱（现取 `sort -u`）**：`{9, 12, 13, 16}`（＝`min(len,16)`）；**`off` 全谱**：`{0}`（本层显示偏移真值）；**`cp_base` 全谱**：`1…1531`。

### 3.3 探针（`dlopen` 直调；正极 ＝ 主链 `.so`）

```
== selftest ==
SELFTEST mask=0x0f rc=4/4
== positive feed (off=7) ==
FEED rc=0 find=0 count=1 npts=5 cp_base=200 off=7 state=2
READBACK mismatches=0/10
== negative (no source / intra-leg) ==
FIND(unsourced)=-1 NPTS(oob)=-1 CPAT(oob)=-1 STATE(oob)=-1
FEED(null-para)=-10000 FEED(null-cp)=-10000 FEED(null-dcp)=-10000 FEED(neg)=-10000 FEED(over)=-10000
== reverse legs (该红必红) ==
REVERSE order=-10000 dup=-10000 back=-10000 off=-10000 end=-10000 find(rejected)=-1
== summary ==
PROBE selftest_mask=0x0f readback_mism=0 reverse_all_red=1 find(rejected)=-1 rc=0   （MAIN_RC=0）
```

### 3.4 🔴 **反腿副本**（结构校验被门在 `WPF_PTS_CPDCMAP_FAKE` 上＝**静默半通**；该红必红）

`~/tA70-work/replica.so` ＝ **`6b28f308bb8d4d24`**（仓外副本 `~/tA70-work/replica-native/`：把入站的**结构校验**条件化为"受 `WPF_PTS_CPDCMAP_FAKE` 控制"，其余逐字同 —— 即"**收下并声称成功却不校**"的静默半通形态；**主链一字未含该路径**）。

```
SELFTEST mask=0x07 rc=PARTIAL
REVERSE order=0 dup=0 back=0 off=0 end=0 find(rejected)=1
PROBE selftest_mask=0x07 readback_mism=0 reverse_all_red=0 find(rejected)=1 rc=1   （REPLICA_PROBE_RC=1）
```

⇒ **该红必红（两条独立证据）**：① **自检位** `0x0f→0x07`（bit3 **乱序/非双射必红位**当场灭）；② **探针反腿** `order/dup/back/off/end` 由 `-10000` 全变 `0` ∧ `find(rejected)` 由 `-1` 变 `1`。⇒ 本条的"**只校不算的校验器**"**不是恒真断言**（它能把"收下却不校"照出来）。

### 3.5 反极腿（`WPF_CPDCMAP_FEED=0`；同一权威件）

| 量 | `after`（缺省） | `rev`（`=0`） |
|---|---|---|
| `[CPDCMAP]` 行总数 | **50**（25 native ＋ 25 mgd） | **0** |
| 本趟自定判据 `CPDCMAP_GUARD`（＝ `mgd>0 ∧ 全部 mism=0 ∧ 全部 pair_match=1`；命令见 §4） | **PASS** | **FAIL**（无正读数 ⇒ 红） |
| `PTS_GUARD`／`PTS_COLORANCHOR`／症状门 | `PASS legs=2/2`／`PASS hits=3`／逐格 | **同**（如实记：本通道**观测用、不承重像素** ⇒ 这两门**不因它翻红**） |

> ⚠️ **如实披露（防读宽）**：本通道**不改变渲染**，所以反极腿的 `PTS_GUARD`／`PTS_COLORANCHOR` **两腿同值**（`colors 1220/636`、色锚不变）⇒ "无映射 ⇒ 该红必红"**由本趟自定判据 ＋ §3.4 副本承担**，**不**由页门承担（页门在这条面**结构性不可分**）。

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

⇒ **零回归**（逐字节相同）。

---

## §4 门禁（现取；`rc` 一律取自 `>out 2>err; echo $?` 形态）

| 门 | 读数 | rc |
|---|---|---|
| `nm==exports` | `nm -D --defined-only` ＝ **778** ＝ `exports.txt` 行数；**逐名 `diff` 零差异**；**新增 15 名、无消失**（＋`WpfLinuxWin32_PtsCpDcpMap{Feed,Count,Find,State,NPoints,CpBase,Offset,Seq,CpAt,DcpAt,Rx,RxGap,Empty,SelfCheck,SelftestMask}`） | 0 |
| `PTSGAP` | `PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=c5acc47490098ff0 exports=778`（`tool/ops/impl` **未动**；`PTSGAP_HISTORICAL=n=11`；`PTSGAP_CITED=PASS refs=1`） | 0 |
| `DEFREG` | `PASS declared=225 route_ids=225`；`DECLDRIFT=0 keys=-` | 0 |
| `REPORTID` | `PASS files=345 ids=2257 declared=225`（本件落盘前 `344` ⇒ 落盘后 `345`，`+1` 即本件） | 0 |
| `HANDOFF_MV` | `PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none`（已按第 `28` 条契约在 `HANDOFF-NEXT.md` 文件尾**只增**追写机器值契约行，`inputs_fp dc1c1f5a…→d59710f3…`） | 0 |
| `GEN_IDEMPOTENT` | 连跑两次：全部 `*.Linux.cs` 合并 `sha16` ＝ `ca375306b3dcb629`（两次同值） | 0 |
| **本趟自定判据** `CPDCMAP_GUARD` | `mgd>0 ∧ 全部 mism=0 ∧ 全部 pair_match=1`（命令：`grep -a '\[CPDCMAP\] mgd' <leg>/app_g1.log` 取计数）；`after` ⇒ **PASS**（25/25/25）；`rev` ⇒ **FAIL**（0 条正读数） | 0／1 |

---

## §5 逐件 `sha16`（现取）

| 件 | 改前 | 改后 |
|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `9898ddf503e101bd`（751361 B） | **`4ec3e0dfe2950b06`**（769019 B／10416 行） |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so`（**非仓内件**） | `a5e9e090a6a64273`（514512 B） | **`c5acc47490098ff0`**（524008 B） |
| `src/WpfGfx.Linux.Native/bin/exports.txt`（**非仓内件**） | `b18279c21205a6f3`（763 行） | **`92c091935f07df42`**（778 行） |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `be0bfd844be2f4b2` | **`8f7099defa925673`**（629 行） |
| `build/PresentationFramework.Linux/reapply-patches.py`（生成器） | `fd06cd5cda068787` | **`12b69807e6846637`**（160656 B） |
| `…/TextParaClient.Linux.cs`（重产件） | `68d73bd2e8988456` | **`4e35c14a1cf8809e`**（211990 B；＋4 行：喂料调用 ＋ 注释） |
| `…/PresentationFramework.Linux.csproj`（重产件） | `b2497e058fafb3bc` | **`e4dbecf5e0b3b752`**（＋2 行：新件 `<Compile Include>`） |
| `…/WpfLinuxCpDcpMapProbe.Linux.cs`（重产件 · **本趟新建**） | — | **`9e8867f91e12207f`**（6377 B／125 行） |
| `build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll`（**非仓内件**） | `0e9d02917de9379b`（6144512 B） | **`75f1a79441d01b16`**（6149120 B） |
| `docs/ROUTES.md` | `97cd86579bd2b224`（1130 行） | **`57a77e0df44834a6`**（1131 行） |
| `build/MilBridge/HANDOFF-NEXT.md` | `6650fe2f5667655a`（765 行） | **`f4197a708a005892`**（767 行；文件尾**只增**两段机器值契约行） |
| `docs/WAVE66-PREREGISTRATION.md`（**冻证据**） | `bf6b683d94549087` | **未变**（`bf6b683d94549087`） |

> ⚠️ 生成器**重产件**里 `PtsCache.Linux.cs`／`FlowDocumentView.Linux.cs`／`FlowDocumentPage.Linux.cs`／`PtsPage.Linux.cs`／`PtsHelper.Linux.cs`／`FigureParaClient.Linux.cs`／`ContainerParaClient.Linux.cs`／`FlowDocumentFormatter.Linux.cs`／`FlowDocumentPaginator.Linux.cs`／`WpfLinuxChainProbe.Linux.cs`／`WpfLinuxTextSrcProbe.Linux.cs` **逐字节未变**（幂等现取）。

---

## §6 诚实边界（**防读宽**，逐条）／具名 `NOINFO`

1. 🔴 **本条只判"偏移映射由宿主给定 ∧ 本侧只校不算 ∧ 可逐条现取 ∧ 可逐点对拍 ∧ 可两极化"**；**不**判"排版前进"、**不**判"`W` 解除"（三腿四帧逐字节同 ⇒ **零像素位移**）。
2. 🔴 **"只校"不是"对真值"**：校验的是**自洽性**（单调／端点／双射／守恒／越界），**不是**与外部 LS 真值对拍；契约 §5 反腿 (a)"偏移错一"**须外部真值** ⇒ 今天**不跑**（标"随内容层那一波"）。
3. 🔴 **"本侧不是作者、也不自算"**：偏移映射由**托管**（宿主）产出；native **只接收／校验／保管／回读**（契约 `outOfScope`：**不得**由本侧自算 `dcp`）。
4. 🔴 **本层显示偏移真值 ＝ 0（如实声明）**：本移植绕过 LS 造型、链上无隐藏文本 ⇒ `dcp==cp`；**不伪造**非零偏移。⚠️ 对 `±1` 反腿**无判别力**（该反腿**不靠**本层，须外部 LS 真值）。
5. 🔴 **`PTS_GUARD`／`PTS_COLORANCHOR` 在本条面上不可分**：本通道**观测用**、**不承重像素** ⇒ 反极腿这两门**同值**；"无映射 ⇒ 该红必红"由**自定判据 ＋ §3.4 副本**承担。
6. 🔴 **有界性（如实记）**：在册条数 ≤ `8`、单条 ≤ `16`（幂等/托管侧有界）、单表点数 ≤ `64`；**表满 ⇒ 有界复用最旧槽**（具名行带 `slot=`）。本趟 25 段**落在 8 槽上轮转**（`slot=0..7` 循环）⇒ 回读面是"**最近 8 段**"视图，**不是**全量台账（**明示，防读成全量**）。
7. **具名 `NOINFO`（逐条给"消掉条件"）**：
   - **`NOINFO-C4-EXTERNAL-TRUTH`**：本侧**无**外部 LS 真值（真 LS 会话里的 `dcp`）⇒ 契约 §5 反腿 (a)"偏移错一"**不可判**。**消掉条件**：真 LS 会话进链（`PRECOND-LS-SESSION-DRIVER`）后，本侧拿 `dcp` 真值与宿主给定偏移**对拍**。
   - **`NOINFO-C4-CROSS-PARA-TABLE`**：契约 §5 反腿 (b)"跨段复用同一 `plsrun` 表"**无 `plsrun` 面** ⇒ 不可判（承 `C2`）。**消掉条件**：`C2` 的 `plsrun` 那半落地。
   - **`NOINFO-C4-LS-WINDOW`**：偏移映射在**真 LS 造型窗**（`LoCreateLine` 系）里的取得路径本侧未开。**消掉条件**：本侧成为重入方并驱动 `Lo*`。
8. **未跑整趟 `verify-all`**（照派单）；本节所有"不得读成绿"的口径照在册红榜 `P1–P10`。

---

## §7 遗留（下一增量具名靶）

- **`W` 余项**：`C2`（`plsrun` 那一半）／`PRECOND-NO-LINE-BREAKER`／`PRECOND-NO-TEXT-PARA-IN-CHAIN`／`PRECOND-LS-SESSION-DRIVER` **未解除**；本件**不**授权任何判据放宽。
- **最近的一格（可选）**：把入站表的**有界视图**升为"按证据序号可追"（同 `T-A69` 的 `ev_seq` 建议）。
- **越级项（须队长裁定）**：契约 §5 两条必红反腿 (a)(b) 的**真执行**须 `PRECOND-LS-SESSION-DRIVER`（本侧成重入方）＋ 度量源 —— 二者是判据 `:100` 的六条合取之 ④（行盒）的真前置。

---

`P1-TAIL2-C4 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 43d07be76a8d28f7（末行＝本行）`

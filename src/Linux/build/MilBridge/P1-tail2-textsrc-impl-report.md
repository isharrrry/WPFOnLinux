# `P1-tail2` · `T-A69` · **内容源入站（字符序列）**（`W` 合取② `PRECOND-NO-TEXT-SOURCE`；`TASK-0307` 增量）—— 实现报告

**判决**：把「**内容源入站**」做成 native 侧的**真入站通道 ＋ 逐段只读回读面 ＋ 两极化自检**：**托管侧**（生成器重产件 `WpfLinuxTextSrcProbe.Linux.cs` ＋ `TextParaClient.Linux.cs` 一处调用）在**同一次调用窗内**把**文本段落的字符序列**（`Paragraph.Element` 的 `ContentStart..ContentEnd`）交给 native；native 在**窗内逐字节值拷贝**进本模块自持表（照 `t141`／`T-A68` 的「窗内值化」纪律），并提供 `Find/Cch/Bytes/CpOff/Char/Hash` 回读口。**真腿现取（`after`）**：`[TEXTSRC] mgd … cch=… bytes=… mism=0 hash_match=1 state=2 v=CONTENT-SOURCE-INBOUND` **×25**（`cch 9…882`、`bytes 18…1764`；**逐字节对拍全中**）＋ native `[TEXTSRC] rx=OK … claimed=1 …` **×25**。**两极化**：探针 `[TEXTSRC-SELFTEST] mask=0x0f`（4/4）；**反腿副本**（喂料静默半通）⇒ `mask=0x0e`／`mism=10/10`／`BYTECMP match=0`／`PROBE_RC=1`（**该红必红**）；**反极腿**（`WPF_TEXTSRC_FEED=0`）⇒ 本侧 `[TEXTSRC]` 行 **0 条**。**零回归**（改前/改后/反极三腿四帧**逐字节同**；`PTS_GUARD=PASS`／`PTS_COLORANCHOR=PASS hits=3`）。**导出面**：`exports 747→763`（逐名 **+16**、**无消失**），`nm==exports`；`PTSGAP`／`DEFREG`／`REPORTID`／`HANDOFF_MV` rc=0。🔴 **如实划界（本件的核心判决）**：**入站 ≠ 排版** —— 本条**不**填任何几何／行盒／`dcp` 区间，**不**解除 `W`；`PRECOND-NO-TEXT-SOURCE` 的字面（"本侧无字符源"）**只在"字符序列"这一半**不再成立，**`cp↔dcp` 偏移（契约 `C4`）仍不在本侧**（本趟**只收不算**：`cp` 由托管给出）。

- **读时**：`2026-10-01T23:2x–23:3x+0800`（本席现取；各条另注）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`（**未 `git add/commit/push`**）；开工 `HEAD=bef0107`（`T-A68`）。
- **改前件备份（仓外 `~/tA69-work/bak/`，`cp -p`，取在**任何写之前**）**：`win32_pts.c`（`065d204796aec958`／735288 B）／`bin/libwpfwin32.so`（`0e15268163bbbd71`／504920 B）／`bin/exports.txt`（`5b3e3fbef2e0631d`／747 行）／`tools/pts-gap-decl.txt`（`880eb83a4b195133`／606 行）／`build/PresentationFramework.Linux/reapply-patches.py`（`b6a3a24137a77ddf`）／其重产件（`bak/generated/` 全套）／`PresentationFramework.Linux.csproj`／`PresentationFramework.dll`（`1c6c58df6d757f3f`）／`docs/ROUTES.md`／`build/MilBridge/HANDOFF-NEXT.md`。
- **写域（逐件）**：`src/WpfGfx.Linux.Native/src/win32_pts.c`（**加一段 `T-A69` 块**：入站通道 ＋ 只读回读面 ＋ 两极化自检）／`src/WpfGfx.Linux.Native/bin/exports.txt`（**构建重产**，非手改）／`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（DECL 行 `so16`／`exports` 跟权威件换 ＋ 只增一段 `T-A69` 重锚）／**生成器** `build/PresentationFramework.Linux/reapply-patches.py`（新增 `TEXTSRC_PROBE_FILE`／`TEXTSRC_PROBE_TEXT` ＋ `TPC_E_VV_REPL` 一处调用 ＋ `materialize_derived()` 写新件 ＋ `PATCH_C` 一行 `<Compile Include>`）／**其重产件**（`WpfLinuxTextSrcProbe.Linux.cs` **新建件**、`TextParaClient.Linux.cs`、`PresentationFramework.Linux.csproj`）／**复述位现值位**（`docs/ROUTES.md` `TASK-0307` 行加一条 dated 结账；`build/MilBridge/HANDOFF-NEXT.md` 文件尾机器值契约 `cell=#1／#3` 追写）／**新建载体** 本件。
- **未改**（如实体例）：`docs/WAVE66-PREREGISTRATION.md`（冻证据 `w66pre16=bf6b683d94549087` 未动）；`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`src/WpfGfx.Linux.Native/src/win32_classification.c`（本趟**未移动**它们所持的 `tool/ops/impl` 三格 ⇒ `PTSGAP` 判据**要求**它们**不动**，见 §4）；`src/WpfGfx.Linux.Native/bin/libwpfwin32.so`／`bin/exports.txt`／`build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` 属**构建产物**（不入库）。
- **黑名单遵守**：未动 `build/MilBridge/tools/**`（**只读跑**判据件）／`verify-all.sh`／`build/close-wave.sh`／`build/shims/**`／`upstream/**`（只读）；**未跑**整趟 `verify-all`；未改相位位；未 `git add/commit/push`。
- **重活**：**2 趟 native 构建**（含 `--symbols`）＋ **1 趟托管构建**（`0 警告 0 错误`，`24.5 s`）＋ **3 趟跑器**（`before`／`after`／`rev`，共 **6 条腿**），全走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- <cmd>`（逐趟 `HEAVYSLOT=ACQUIRED/MEMOK/RELEASED rc=0`）；进程只按 PID；显示位只用装置自分配的号（`DISPLAY_PICK :231`）；禁 `sleep` 轮询；写前 `cp -p`；`temp+rename`（生成器 `_write_atomic`）；模式守恒。
- **口径**：一切读数**本席现取**（`sha256sum`／`nm -D --defined-only`／`diff`／`grep -c`／`gcc` 编译的 `dlopen` 探针 `~/tA69-work/probe`／`python3`＋`PIL` 自算逐像素 `AE`／只读跑 `bash build/MilBridge/tools/{pts-gap-count-check,pts-pages-guard,defect-registry-check,report-id-domain-check,handoff-machine-values-check}.sh`）。凡引他件处一并标注。

---

## §0 结论速览（自包含）

1. ✅ **「内容源入站」= 真入站（现取）**：`after` 腿 `app_g1.log` 里 `[TEXTSRC] rx=OK … v=CONTENT-SOURCE-INBOUND` **25 条** ⇒ 托管在真应用里把**25 个文本段落**的字符序列交进 native；`before` 腿 **0 条**（旧件无此通道）。
2. ✅ **逐段字符序列可现取（长度／字节／偏移 ＋ 逐字节对拍）**：`[TEXTSRC] mgd … cch=… bytes=… cp=… mism=0 hash_match=1` **×25**（`cch ∈ {9,12,13,16,22,38,40,568,588,882}`；`bytes=cch*2`；`cp ∈ 2…1531`）⇒ **逐字符对拍零失配** ∧ **独立算的 FNV-1a 64 逐字节相符**（托管侧 `Fnv1a(text)` vs native 对**副本字节流**算的 `Hash(k)`）。
3. ✅ **两极化（该红必红）**：① 探针 `[TEXTSRC-SELFTEST] mask=0x0f`（4/4：入站／`EMPTY≠NONE`／反极必拒／无源不漏）；② **反腿副本**（`~/tA69-work/replica/libwpfwin32.so c3abd55c0cd33d96`，喂料**静默半通**）⇒ `mask=0x0e`、`PROBE readback_mism=10/10`、`BYTECMP match=0`、`PROBE_RC=1` ⇒ **判据当场红**；③ **反极腿**（`WPF_TEXTSRC_FEED=0`，同一权威件）⇒ `[TEXTSRC]` 行 **0 条**（无源可读）。
4. ✅ **零回归**：`.so 0e15268163bbbd71（改前）→ a5e9e090a6a64273（改后）`／`pf 1c6c58df6d757f3f → 0e9d02917de9379b`；三腿（`before`／`after`／`rev`）四帧**逐字节相同**（`AE=0`；`boot b21eb530afd3c66c`／`k23 10d0b9d54e649c10`／`k24 0bdb2dfd05952bc9`／`last 10d0b9d54e649c10`）、症状门逐格同；`PTS_GUARD=PASS legs=2/2`／`PTS_COLORANCHOR=PASS k=24 hits=3` **未回退**。
5. ✅ **门禁四件（现取）**：`nm -D --defined-only` ＝ `exports.txt` ＝ **763**（逐名 `diff` 零差异；**+16 无消失**）；`PTSGAP=PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=a5e9e090a6a64273 exports=763`（rc=0）；`DEFREG=PASS declared=225 route_ids=225`（rc=0，`DECLDRIFT=0`）；`REPORTID=PASS files=343 ids=2257 declared=225`（rc=0）；`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0`（rc=0）。
6. 🔴 **如实划界（本件的核心判决）**：本条**只**判「**字符序列可从托管入站、可逐段现取、可与托管真值逐字节对拍、可两极化**」。它**不**判「`W` 解除」—— `PRECOND-NO-LINE-BREAKER`／`PRECOND-LS-SESSION-DRIVER`／`PRECOND-NO-TEXT-PARA-IN-CHAIN`／`C2`／`C4` **仍在册**；`PRECOND-NO-TEXT-SOURCE` 的字面**只在"字符序列"这一半**不再成立（`cp↔dcp` 偏移那一半**仍不成立**，本趟**只收不算**）。

---

## §1 「内容源入站」的**准入判据**（现取：件:行 ＋ 满足／不满足）

> **判据一律逐字引自**已登载的判据件（件:行）；行号只保证本次有效（内容锚原文一并给）。

### 1.1 在册出处（逐字）

| 角色 | 件:行 | 现取原文（要点） |
|---|---|---|
| **前置本体（本条的靶）** | `build/MilBridge/P1-layout-content-criteria.md:112` | 「**`PRECOND-NO-TEXT-SOURCE`**：本侧无字符/`dcp` 内容源。」 |
| **准入的形式条件** | `build/MilBridge/P1-tail2-dingrecon.md:98`（§3.2 判据化） | 「**当且仅当** `W` 每项在同一趟腿上有**可现取的真读数／具名留痕**（`P10`）时，"内容层那一波"＝**已落地**。」（本条 ＝ `W` 第 ② 项，`dingrecon.md:92`） |
| **可判据化定义（"入站证明"的原始要求）** | `P1-layout-content-criteria.md:100`（`acceptance` 六条合取之③） | 「③ `dcpFirst/dcpLim` 与**真实字符源**一致（须给"字符源"的**入站证明**）」 |
| **前置三分（缺一不可）** | `P1-layout-content-criteria.md:102` | 「**前置（三条，缺一不可）**：**(i)** 内容源入站通道（见 §5 的越级）；**(ii)** 行断器；**(iii)** 链上真的出现**文本段落**。」 |
| **源在谁手上（`P9` 边界）** | `P1-layout-content-criteria.md:146` | 「**源在宿主侧**（托管 `TextContainer`/`TextFormatter`……）……本件只判"**取它要开新面**"」 |
| **本侧不是作者（铁律）** | `build/MilBridge/P1-ls-callback-face-recon.md` §5.1 | 「`LS-CB-M1` 的 **9 槽没有一槽本侧能作为作者产出** —— 它们**全部是"向宿主取"**」 |

⇒ **本条把"内容源入站"判据化（写死）为四条合取**：**(a) 有一条真入站通道**（字符序列从宿主侧进入本侧）；**(b) 本侧能逐段读到该序列／长度／偏移**；**(c) 与托管侧真值逐字节对拍相符**；**(d) 两极化：无源 ⇒ 该红必红**。

### 1.2 逐条现取（满足／不满足）

| # | 判据 | 现取读数（`after` 腿／探针） | 判定 |
|---|---|---|---|
| **(a) 入站通道** | 托管把字符序列交进 native ⇒ `[TEXTSRC] rx=OK` 计数 `0→25`；`before` 腿 **0** | ✅ **满足**（`wsrc/win32_pts.c` `WpfLinuxWin32_PtsTextSrcFeed` ＋ 生成件 `WpfLinuxTextSrcProbe.FeedParagraph`；调用点 `TextParaClient.Linux.cs:99`） |
| **(b) 逐段可读** | `Find/Cch/Bytes/CpOff/Char/Hash` 逐段现取；`mgd` 行 `cch=… bytes=… cp=… slot=…` ×25（25 个**互异** `parah`） | ✅ **满足** |
| **(c) 逐字节对拍** | `mgd` 行 `mism=0` **25/25** ∧ `hash_match=1` **25/25**；探针 `BYTECMP managed_truth_hash=300b4cca9f55c9bc native_hash=300b4cca9f55c9bc match=1` | ✅ **满足** |
| **(d) 两极化** | 探针 `SELFTEST mask=0x0f`；反腿副本 `mask=0x0e`／`mism=10/10`／`match=0`／`rc=1`；反极腿 `[TEXTSRC]` 行 `25→0` | ✅ **满足** |
| **(e) 附带**：段落身份可认领 | native `rx=OK … claimed=1` **25/25** ⇒ `_paraHandle` 在本侧 N1 台账里**按对象身份可认领** | ✅（**诊断**，不参与收/拒） |

### 1.3 🔴 「满足」的**射程**（写死，防读宽）

1. **"字符源"这一半满足，"`dcp` 映射"那一半不满足**：本趟**入站的是字符序列 ＋ 段落起始字符偏移 `cp`（由托管给出）**；`cp↔dcp` 的**偏移关系（契约 `C4`）本侧仍不自算、仍不在本侧**（`P1-ls-provenance-contract.md:72` 在册）⇒ `PRECOND-NO-TEXT-SOURCE` 的字面**只减掉一半**，**整条不判"解除"**。
2. **"入站"不构成"排版"**：本条**不**填 `cLines`／`dcpFirst/dcpLim`／行盒中的任何一格（那些还要 `PRECOND-NO-LINE-BREAKER` ＋ 度量源）⇒ 判据 `:100` 的六条合取之 ③ 的**可判性**已被本条**向前推进一格**（从"无入站证明"到"有入站证明"），但该合取的 ②④⑤ 仍**未达**。
3. **"同一窗内"的语义（写死）**：入站与对拍发生在**托管方法的一次调用窗内**（`TextParaClient.ValidateVisual` 内：喂料 ⇒ 立刻回读 ⇒ 对拍）；native 侧对**入参指针只在窗口内**逐字节值拷贝（指针出窗即不可用）。⚠️ 这**不是** LS 的 `LoCreateLine` 会话窗 —— 那一格仍缺（`PRECOND-LS-SESSION-DRIVER`）。

---

## §2 改动（逐处）

### 2.1 native：`src/WpfGfx.Linux.Native/src/win32_pts.c`（新增一段 `T-A69` 块，`:5274–5508`）

1. **常量／结构**：`WPF_PTS_TEXTSRC_{MAX=8,CCH_MAX=8192,ST_NONE/EMPTY/VALUE,MAGIC}` ＋ `wpf_pts_textsrc`（`parah`／`claimed`／`cp_off`／`cch`／`bytes`／`state`／`seq`／`hash`／`wch[CCH_MAX]`）。
2. **入站（唯一收口）** `WpfLinuxWin32_PtsTextSrcFeed(parah, cp_off, pwch, cch)`：先过**四条拒面**（`null-para`／`null-text`／`negative-cch`／`cch-over-bound`）⇒ 拒时**表内不出现该段** ＋ 具名 `[TEXTSRC] rx=REJECT …out=UNWRITTEN bytes=0`；收时**窗内 `memcpy`** ＋ FNV-1a 64（对副本字节流）＋ `seq` ＋ 三态 ＋ 具名 `[TEXTSRC] rx=OK …`。
3. **只读回读面**（导出）：`Count`／`Find`／`State`／`Cch`／`CpOff`／`Bytes`／`Claimed`／`Seq`／`Char(k,i)`（越界 ⇒ `-1`）／`Hash(k)`／`Rx`／`RxGap`／`Empty`。
4. **两极化自检** `WpfLinuxWin32_PtsTextSrcSelfCheck()`：夹具（文件级静态身份 ⇒ 地址稳定互异）跑 4 位；收尾**真销毁 ＋ 复原全部可观测状态**（含 `g_pts_sub_claim_{ok,bad}`）；表位不足／泄漏 ⇒ `-1`（**不算绿**）。
5. **Fake 路径**：**不在主链**；反腿**只在仓外副本**（`~/tA69-work/replica/`，见 §3.4）。

> 🔴 **无假值纪律（四条）**：① 失败路径**一字不写**（表内无该段）；② 无源 ⇒ `Find==-1`（**不**用零值／空串冒充"有源"）；③ `cch==0`（`EMPTY`）与"根本没入站"（`NONE`）**不同形**；④ 越界 ⇒ **拒**（不截断、不静默）。

### 2.2 生成器：`build/PresentationFramework.Linux/reapply-patches.py`

| 项 | 内容 |
|---|---|
| `TEXTSRC_PROBE_FILE`／`TEXTSRC_PROBE_TEXT` | **新建件** `WpfLinuxTextSrcProbe.Linux.cs`：`Enabled`（闸 `WPF_TEXTSRC_FEED`，**缺省开**、**只有**显式 `"0"` 才关）／`FeedParagraph(parah, para)`（`Marshal.StringToCoTaskMemUni` ⇒ 调 native ⇒ **立即回读 native 副本**并逐字符 ＋ `Fnv1a` 对拍 ⇒ 一行 `[TEXTSRC] mgd …`）／`Fnv1a(string)`（与 native **逐字节**同法） |
| `TPC_E_VV_REPL`（＋3 行） | 在 `TextParaClient` 的 `ValidateVisual` 内（既有 `FsQueryTextDetails` 之后）加 `WpfLinuxTextSrcProbe.FeedParagraph(_paraHandle, Paragraph);` —— **纯增**、不改任何既有控制流 |
| `materialize_derived()` | 多写一个**非派生新建件**（`_write_atomic`：`temp + fsync + os.replace`） |
| `PATCH_C` | 多一行 `<Compile Include="…/WpfLinuxTextSrcProbe.Linux.cs" />` |

**幂等（现取）**：连跑两次，全部 `*.Linux.cs` ＋ `csproj` 的合并 `sha16` **两次同值** `18953296f3352923` ⇒ `GEN_IDEMPOTENT=YES`。

### 2.3 为什么落在**托管侧**（不是纯 native）

native **结构性看不到内容**：字符序列的**作者是宿主**（`TextContainer`），且 `TextParaClient`／`ValidateVisual` 是**托管内部虚方法、无 P/Invoke**（`exports.txt` 里 `updateviewport` 命中 **0**）⇒ "把该段的字符序列交出来"只能**由托管发起**。native 侧只做**入站 ＋ 保管 ＋ 回读 ＋ 自检**（**不**自造一字）。

---

## §3 成对读数

### 3.1 三腿（**只差权威 `.so`／`pf` 或一个 env**；同装置 `:231`；证据 `~/tA69-work/legs/`）

| 腿 | 权威 | env | 证据目录 | `LEGS_RUNNER` |
|---|---|---|---|---|
| `before` | `.so 0e15268163bbbd71`／`pf 1c6c58df6d757f3f`（改前） | — | `~/tA69-work/legs/before/` | `PASS requested=2 obtained=2 refused=0` |
| `after` | `.so a5e9e090a6a64273`／`pf 0e9d02917de9379b`（改后） | — | `~/tA69-work/legs/after/` | `PASS requested=2 obtained=2 refused=0` |
| `rev`（**反极腿**） | 同 `after` | `WPF_TEXTSRC_FEED=0` | `~/tA69-work/legs/rev/` | `PASS requested=2 obtained=2 refused=0` |

同批工具（现取）：`runner_sha16=330a90f1f0ac28e4`／`session_sha16=f1a582d9ea9788c9`／`guard_sha16=ead59d60ccfc95b0`／`legs-to-env.py=ed290f41e5ae6432`。

### 3.2 靶面成对（`grep -c` 现取，`app_g1.log`）

| 量 | `before`（改前） | `after`（改后／缺省） | `rev`（`FEED=0`） |
|---|---|---|---|
| `[TEXTSRC] mgd`（托管对拍行） | **0**（旧件无此面） | **25** | **0** |
| `… mgd … mism=0` | — | **25/25** | — |
| `… mgd … hash_match=1` | — | **25/25** | — |
| `… mgd … v=NO-SOURCE` | — | **0** | — |
| `[TEXTSRC] rx=OK`（native 入站行） | **0** | **25** | **0** |
| `[TEXTSRC] rx=REJECT` | **0** | **0** | **0** |
| `rx=OK … claimed=1` ／ `claimed=0` | — | **25 ／ 0** | — |
| 互异 `parah`（mgd 行内） | — | **25** | — |
| `[HC-UNHANDLED]` ／ `entry point named` ／ `failfast+unrec` | 0 ／ 0 ／ 0 | 0 ／ 0 ／ 0 | 0 ／ 0 ／ 0 |

**逐段字符序列现取（样例，逐字）**：

```
[TEXTSRC] mgd parah=0x61eb72ee09e4 cp=2 cch=882 bytes=1764 rc=0 slot=0 mism=0 hash_match=1 state=2 hash=f32fdfd8af421c46 v=CONTENT-SOURCE-INBOUND
[TEXTSRC] mgd parah=0x61eb72f5a354 cp=703 cch=38 bytes=76 rc=0 slot=1 mism=0 hash_match=1 state=2 hash=84e4efca8d9524fb v=CONTENT-SOURCE-INBOUND
[TEXTSRC] mgd parah=0x61eb72f5ffe4 cp=754 cch=13 bytes=26 rc=0 slot=2 mism=0 hash_match=1 state=2 hash=67b9fc788dd30303 v=CONTENT-SOURCE-INBOUND
```

```
[TEXTSRC] rx=OK slot=3 seq=12 parah=0x61eb72f573a4 claimed=1 cp=1531 cch=588 bytes=1176 hash=a4a91c787f836d6a state=VALUE v=CONTENT-SOURCE-INBOUND
```

**`cch/bytes` 全谱（现取 `sort -u`）**：`(9,18) (12,24) (13,26) (16,32) (22,44) (38,76) (40,80) (568,1136) (588,1176) (882,1764)`。

### 3.3 探针（`dlopen` 直调；正极 ＝ 主链 `.so`）

```
== selftest ==
SELFTEST mask=0x0f rc=4/4
== positive feed ==
FEED rc=0 find=0 count=1 cch=10 bytes=20 cp=11 state=2
READBACK mismatches=0/10 hash=300b4cca9f55c9bc
BYTECMP managed_truth_hash=300b4cca9f55c9bc native_hash=300b4cca9f55c9bc match=1
== negative (no source) ==
FIND(unsourced)=-1 STATE(oob)=-1 CHAR(oob)=-1
FEED(null-para)=-10000 FEED(null-text)=-10000 FEED(neg)=-10000 FEED(over)=-10000
PROBE selftest_mask=0x0f bytecmp_match=1 readback_mism=0 nosource_find=-1 rc=0   （MAIN_RC=0）
```

### 3.4 🔴 **反腿副本**（喂料**静默半通**；该红必红）

`~/tA69-work/replica/libwpfwin32.so` ＝ **`c3abd55c0cd33d96`**（仓外副本：把 `Feed` 的**窗内 `memcpy`** 条件化为"受 `WPF_PTS_TEXTSRC_FAKE` 控制"，其余逐字同 —— 即"**收下并声称成功却不存字符**"的静默半通形态；**主链一字未含该路径**）。

```
SELFTEST mask=0x0e rc=PARTIAL
BYTECMP managed_truth_hash=300b4cca9f55c9bc native_hash=f987af2e35fa45f3 match=0
PROBE selftest_mask=0x0e bytecmp_match=0 readback_mism=10 nosource_find=-1 rc=1   （REPLICA_PROBE_RC=1）
```

⇒ **该红必红（两条独立证据）**：① **自检位** `0x0f→0x0e`（bit0 入站/对拍位**当场灭**）；② **探针对拍** `mism 0→10/10` ∧ `BYTECMP match 1→0`。⇒ 本条的"**逐字节对拍**"**不是恒真断言**（它能把"声称入站但没真存"照出来）。

### 3.5 反极腿（`WPF_TEXTSRC_FEED=0`；同一权威件）

| 量 | `after`（缺省） | `rev`（`=0`） |
|---|---|---|
| `[TEXTSRC]` 行总数 | **50**（25 native ＋ 25 mgd） | **0** |
| 本趟自定判据 `TEXTSRC_GUARD`（＝ `mgd>0 ∧ 全部 mism=0 ∧ 全部 hash_match=1`；命令见 §4） | **PASS** | **FAIL**（无正读数 ⇒ 红） |
| `PTS_GUARD`／`PTS_COLORANCHOR`／症状门 | `PASS legs=2/2`／`PASS hits=3`／逐格 | **同**（如实记：本通道**观测用、不承重像素** ⇒ 这两门**不因它翻红**） |

> ⚠️ **如实披露（防读宽）**：本通道**不改变渲染**，所以反极腿的 `PTS_GUARD`／`PTS_COLORANCHOR` **两腿同值**（`colors 1220/636`、色锚不变）⇒ "无源 ⇒ 该红必红"**由本趟自定判据 ＋ §3.4 副本承担**，**不**由页门承担（页门在这条面**结构性不可分**）。

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
| `nm==exports` | `nm -D --defined-only` ＝ **763** ＝ `exports.txt` 行数；**逐名 `diff` 零差异**；**新增 16 名、无消失**（＋`WpfLinuxWin32_PtsTextSrc{Feed,Count,Find,State,Cch,CpOff,Bytes,Claimed,Seq,Char,Hash,Rx,RxGap,Empty,SelfCheck,SelftestMask}`） | 0 |
| `PTSGAP` | `PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=a5e9e090a6a64273 exports=763`（`tool/ops/impl` **未动**；`PTSGAP_HISTORICAL=n=11`；`PTSGAP_CITED=PASS refs=1`） | 0 |
| `DEFREG` | `PASS declared=225 route_ids=225`；`DECLDRIFT=0 keys=-` | 0 |
| `REPORTID` | `PASS files=344 ids=2257 declared=225`（本件落盘前 `343` ⇒ 落盘后 `344`，`+1` 即本件） | 0 |
| `HANDOFF_MV` | `PASS cells=9 equal=8 manual=1 mismatch=0`（`inputs_fp 9d051a4c…→dc1c1f5a…`，已按第 `28` 条契约在 `HANDOFF-NEXT.md` 文件尾**只增**追写） | 0 |
| `GEN_IDEMPOTENT` | 连跑两次：全部 `*.Linux.cs` ＋ `csproj` 合并 `sha16` ＝ `18953296f3352923`（两次同值） | 0 |
| **本趟自定判据** `TEXTSRC_GUARD` | `mgd>0 ∧ 全部 mism=0 ∧ 全部 hash_match=1`（命令：`grep -a '\[TEXTSRC\] mgd' <leg>/app_g1.log` 取计数）；`after` ⇒ **PASS**（25/25/25）；`rev` ⇒ **FAIL**（0 条正读数） | 0／1 |

---

## §5 逐件 `sha16`（现取）

| 件 | 改前 | 改后 |
|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `065d204796aec958`（735288 B） | **`9898ddf503e101bd`**（751361 B） |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so`（**非仓内件**） | `0e15268163bbbd71`（504920 B） | **`a5e9e090a6a64273`**（514512 B） |
| `src/WpfGfx.Linux.Native/bin/exports.txt`（**非仓内件**） | `5b3e3fbef2e0631d`（747 行） | **`b18279c21205a6f3`**（763 行） |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `880eb83a4b195133`（606 行） | **`be0bfd844be2f4b2`**（622 行） |
| `build/PresentationFramework.Linux/reapply-patches.py`（生成器） | `b6a3a24137a77ddf` | **`fd06cd5cda068787`**（151820 B） |
| `…/PresentationFramework.Linux.csproj`（重产件） | `7dbfcb274d587ba4` | **`b2497e058fafb3bc`**（＋2 行：新件 `<Compile Include>`） |
| `…/TextParaClient.Linux.cs`（重产件） | `3ed7b9011b0b2dc8` | **`68d73bd2e8988456`**（211670 B；＋4 行：喂料调用 ＋ 注释） |
| `…/WpfLinuxTextSrcProbe.Linux.cs`（重产件 · **本趟新建**） | — | **`d0d77fc5a7a822dc`**（6262 B） |
| `build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll`（**非仓内件**） | `1c6c58df6d757f3f`（6144512 B） | **`0e9d02917de9379b`**（6147072 B） |
| `docs/ROUTES.md` | `6f37d596245666e0`（1129 行） | **`97cd86579bd2b224`**（1130 行） |
| `build/MilBridge/HANDOFF-NEXT.md` | `fbe82401f8eac611`（762 行） | **`ebb5f80907fe7647`**（763 行） |
| `docs/WAVE66-PREREGISTRATION.md`（**冻证据**） | `bf6b683d94549087` | **未变**（`bf6b683d94549087`） |

> ⚠️ 生成器**重产件**里 `PtsCache.Linux.cs`／`FlowDocumentView.Linux.cs`／`FlowDocumentPage.Linux.cs`／`PtsPage.Linux.cs`／`PtsHelper.Linux.cs`／`FigureParaClient.Linux.cs`／`ContainerParaClient.Linux.cs`／`FlowDocumentFormatter.Linux.cs`／`FlowDocumentPaginator.Linux.cs`／`WpfLinuxChainProbe.Linux.cs` **逐字节未变**（幂等现取）。

---

## §6 诚实边界（**防读宽**，逐条）／具名 `NOINFO`

1. 🔴 **本条只判"字符序列可入站 ∧ 可现取 ∧ 可对拍 ∧ 可两极化"**；**不**判"排版前进"、**不**判"`W` 解除"（三腿四帧逐字节同 ⇒ **零像素位移**）。
2. 🔴 **"入站"不是"本侧是作者"**：字符序列由**托管**（宿主 `TextContainer`）产出；native **只接收／保管／回读**（`P1-ls-callback-face-recon.md` §5.1 铁律同向）。
3. 🔴 **`cp↔dcp` 不在本条**：入站的是**字符序列 ＋ 托管给出的 `cp` 起始偏移**；`cp↔dcp` 的**对应关系仍不在本侧**（契约 `C4`，`P1-ls-provenance-contract.md:72`）⇒ `PRECOND-NO-TEXT-SOURCE` **只减一半**。
4. 🔴 **"同一窗"是托管方法窗，不是 LS 会话窗**：`PRECOND-LS-SESSION-DRIVER`（`P1-ls-callback-face-recon.md:85`）**仍成立** —— 本侧仍未成为"托管→本侧→托管"的**重入方**；`FullText` 只在 LS 造型窗内非空（`LineServicesCallbacks.cs:3448` `FullText = _owner as FullTextState`）而本移植**绕过 LS 造型**（`build/PresentationCore.Linux/TextFormatterImp.Linux.cs`）⇒ 该格**结构性不可达**（**不冒充**）。
5. 🔴 **`PTS_GUARD`／`PTS_COLORANCHOR` 在本条面上不可分**：本通道**观测用**、**不承重像素** ⇒ 反极腿这两门**同值**；"无源 ⇒ 该红必红"由**自定判据 ＋ §3.4 副本**承担。
6. 🔴 **`claimed=1` 的射程**：它只主张"该 `pfspara` 句柄**在本侧 N1 台账里可认领**（＝ `&wpf_pts_subtrack->c_paras`）"；**不**主张"该句柄在托管表里 live ∧ 解析到同一对象"（那是托管侧判据）。
7. 🔴 **有界性（如实记）**：在册条数 ≤ `8`、单条 ≤ `8192` 字符；**表满 ⇒ 有界复用最旧槽**（具名行带 `slot=`）。本趟 25 段**落在 8 槽上轮转**（`slot=0..7` 循环）⇒ **回读面是"最近 8 段"视图**，**不是**全量台账（**明示，防读成全量**）。
8. **具名 `NOINFO`（逐条给"消掉条件"）**：
   - **`NOINFO-TEXTSRC-DCP-MAP`**：`cp↔dcp` 映射（契约 `C4`）不在本侧。**消掉条件**：宿主给定该映射（本侧**只能复算校验、不得自算**）。
   - **`NOINFO-TEXTSRC-LS-WINDOW`**：字符源在**真 LS 造型窗**（`LoCreateLine` 系）里的取得路径本侧未开（`PRECOND-LS-SESSION-DRIVER`）。**消掉条件**：本侧成为重入方并驱动 `Lo*`。
   - **`NOINFO-TEXTSRC-NO-TEXT-PARA-IN-CHAIN`**：本趟喂料点是 `TextParaClient.ValidateVisual`（**文本段落客户端**）—— 链上**确出现文本段落**（现取：**25 个互异段落**各喂一次，`cch 9…882`）；但"**跨页/整页**"结论**不由本条宣布**（粒度 ＝ 单段落，承契约 `:100`）。
9. **未跑整趟 `verify-all`**（照派单）；本节所有"不得读成绿"的口径照在册红榜 `P1–P10`。

---

## §7 遗留（下一增量具名靶）

- **`W` 余项**：`C2`（`plsrun` 那一半）／`C4`／`PRECOND-NO-LINE-BREAKER`／`PRECOND-NO-TEXT-PARA-IN-CHAIN`／`PRECOND-LS-SESSION-DRIVER` **未解除**；本件**不**授权任何判据放宽。
- **最近的一格（可选）**：把入站表的**有界视图**升为"按证据序号可追"（例如每段一条 `ev_seq`，回读按 `ev_seq` 定位）——今天只有"最近 8 段"。
- **越级项（须队长裁定）**：`PRECOND-LS-SESSION-DRIVER`（本侧成重入方）＋ 度量源（`LS-CB-M1` 的 `GetRunTextMetrics`／`GetRunCharWidths`）—— 二者是判据 `:100` 的六条合取之 ④（行盒）的真前置。

---

`P1-TAIL2-TEXTSRC 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 5fbc5ae1d733ebc3（末行＝本行）`

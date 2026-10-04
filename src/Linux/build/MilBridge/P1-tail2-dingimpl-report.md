# `P1-tail2` · `T-A74` · **`W` 七条合取现状复核 ＋ 丁类实施** —— 实现报告

**判决**：对 `build/MilBridge/P1-tail2-dingrecon.md`（`T-A67`）§3.2 的 `W`＝**7 项合取**逐条**现取**（同一趟腿／同一权威件）：`①PRECOND-LS-SESSION-DRIVER`／`②PRECOND-NO-TEXT-SOURCE`／`③PRECOND-NO-LINE-BREAKER`／`④PRECOND-NO-TEXT-PARA-IN-CHAIN`／`⑤契约 C4` **判「满足」**（各有可现取真读数：`[LSSESS]`／`[TEXTSRC]`／`[LINEBREAK]`／`[PARACHAIN]`／`[CPDCMAP]`）；**`⑥PRECOND-NEW-CALLBACK-FACE` 判「不满足」**（**形式要件**满足 ∧ **语义**「面**真被用于取内容**」**不满足** —— 本侧**不是**这 28 槽的作者，28 槽**全为入站面**；其作者 `T-A68` 自判「`W` 合取**仍 `7/7` 未解除**」）；**`C2` 判「不满足」**（只落 `LoCreateContext` 的 `ploc` 一半；**`plsrun` 一半在本移植链上结构性不存在**）。⇒ **`W` 7 项中 2 项不满足 ⇒ 不可判「已解除」**。承派单 §① 第 2 条「**若判『未解除』⇒ 如实报停止并具名缺失项**」：**丁类 16 条一条不实施**（现取 16/16 仍缺口：`bin/exports.txt` **逐名 `grep -cx` ＝ 0** ∧ `nm -D --defined-only` **逐名 ＝ 0**）。**决定性判词（本件的核心）**：**即便 `W` 全绿也不解丁类** —— 丁类 16 条的真前置 `L1`（native LS 行引擎，**含度量源**）／`L2`（DWrite 脚本分段）**不在 `W` 的 7 项内**（`T-A67` §4.3 已点名分流；`T-A73` §7 明标度量源为「**越级项、本条未触碰**」），且 **LS 那条链在本移植里已被 shim 替换**（`build/MilBridge/P1-tail2-hostline-recon.md:161` 现取：「native LS 只在**托管 `TextFormatter` 内部**才被用到……而**那一层已被 shim 替换**（生成物 `:692/723`）⇒ 在 native 侧重建 LS **不会**给 `FsQueryLineList*` 多带来任何行盒」⇒ 该族**无真腿可达**，实现即**不可验证**）。**零源码改动**（本趟**无实现**，只写载体 ＋ 复述位现值位）⇒ 门禁**未回退**：`PTSGAP=PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=df27801beb222f05 exports=846`（rc=0）／`nm==exports==846`（逐名 `diff` 零差异）／`PTS_GUARD=PASS legs=2/2`／`PTS_COLORANCHOR=PASS k=24 hits=3`／`PTS_ENFE=PASS total=0`。

- **读时**：`2026-10-02T00:2x–00:5x+0800`（本席现取；各条另注）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`；开工 `HEAD=ab94330`（`P1 尾波2 (#82)：T-A73 W③ 行断器 + T-A72 补 PtsCache——exports 824→846（W 七条合取全部落地）`）；`git status --short` 现取仅 `?? build/MilBridge/tasks-tail2/T-A74.md`（**未 `git add/commit/push`**）。
- **现取件代（本席现取，`sha256` 前 16 位）**：`bin/libwpfwin32.so` ＝ **`df27801beb222f05`**（553936 B）；`bin/exports.txt` ＝ **`83b60726bbc2486e`**／**846 行**；`src/win32_pts.c` ＝ **`31964874821daae4`**／**11458 行**；`tools/pts-gap-decl.txt` ＝ **`b735620eacf6fa4a`**／**705 行**；`upstream/…/TextFormatting/LineServices.cs` ＝ **`8b2bc2167f5c0bd3`**／1620 行（＝ `T-A65` 在册同代）。
- **在册声明行（现取，`tools/pts-gap-decl.txt`）**：`# PTSGAP-DECL: tool=54 dead=11 artifact=1 ops=42 impl=42 so16=df27801beb222f05 exports=846 w66pre16=bf6b683d94549087`（与牙现算**逐值相符**，见 §5）。
- **写域（逐件）**：**新建载体** 本件；**复述位现值位** `docs/ROUTES.md` `TASK-0307` 行加一条 dated 结账（**只增不改**）。**未改**任何 `src/**`（**native 一字未动**）／`bin/exports.txt`／`tools/pts-gap-decl.txt`／生成器 `reapply-patches.py` 及其重产件 —— **本趟无实现** ⇒ 无这些件的改动面（**这正是判「未解除」的必然结果**）。
- **黑名单遵守**：未动 `build/MilBridge/tools/**`（**只读跑**判据件 `pts-gap-count-check.sh`／`pts-pages-guard.sh`；**未跑**会 `--emit` 的 `defect-registry-check.sh` —— 免得手造 `build/MilBridge/tools/**` 的 `M`）／`verify-all.sh`／`build/close-wave.sh`／`build/shims/**`／`upstream/**`（只读）；**未跑**整趟 `verify-all`；未改相位位。
- **重活**：**零构建**（无实现 ⇒ 无编译面）；**未占显示位**（未起跑器）；**未跑新腿** —— 现取**复用** `~/tA73-work/legs/after`（在册权威腿；其五件 `libwpfwin32.so=df27801beb222f05`／`PresentationFramework.dll=93f0368dac89f9c2`／`wpfgfx_cor3.so=941e69902d82ef02`／`PresentationCore.dll=ba162811e97e4484`／`WindowsBase.dll=7f1c38f90e916718` 与本席现取的**当前构建五件逐字节同值** ⇒ **该腿即现状腿**；本趟**零源码改动** ⇒ 无"证据换代"面）；进程只按 PID；禁 `sleep` 轮询。
- **口径**：一切读数**本席现取**（`sha256sum`／`wc -l`／`nm -D --defined-only`／`diff`／`grep -cx`／只读跑 `bash build/MilBridge/tools/{pts-gap-count-check,pts-pages-guard}.sh`）。凡引他件处一并标注。

---

## §0 结论速览（自包含）

1. 🔴 **`W` 逐条现取＝`5 满足 ＋ 1 半 ＋ 1 形式✔语义✗`** ⇒ **2 项不满足**（`⑥`、`C2`）⇒ **`W` 不可判「已解除」**（§1／§2）。
2. 🔴 **承派单 ⇒ 如实报停止**：**丁类 16 条一条不实施**；**不许假成功**（本趟**零实现、零 stub、零导出**）。
3. 🔴 **16/16 仍缺口（现取）**：`Lo*` 12 ＋ 文本分析 4，在 `exports.txt` 逐名 `grep -cx` ＝ **0**、在 `nm -D --defined-only` 逐名 ＝ **0**（§3.1）。
4. 🔴 **决定性判词**：**`W` ⊉ 丁类的真前置** —— `L1`（native LS 行引擎，**含度量源** `LS-CB-M1` 的 `GetRunTextMetrics`／`GetRunCharWidths`）／`L2`（DWrite 脚本分段）**都不在 `W` 的 7 项内**；且 **LS 那条链已被 shim 替换**（`hostline-recon.md:161`）⇒ 16 条**无真腿可达 ⇒ 无两极化可做 ⇒ 不可诚实实施（实施即不可验证）**（§3.2／§3.3）。
5. ✅ **零回归**：本趟**未改任何 `src/**`** ⇒ `.so`／`exports.txt`／`pts-gap-decl.txt` **逐字节未动**；`PTSGAP=PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=df27801beb222f05 exports=846`（rc=0）；`nm==exports==846`；`PTS_GUARD=PASS legs=2/2`／`PTS_COLORANCHOR=PASS k=24 hits=3`／`PTS_ENFE=PASS total=0` **未回退**（§5）。

---

## §1 `W` 七条合取逐条现取（满足／不满足 ＋ 证据件:行／读数）

> **判据一律逐字引自**在册判据件；行号只保证本次有效（内容锚原文一并给）。**现取口径**：`W` 的**形式条件** ＝ `P1-tail2-dingrecon.md:98`（§3.2）：「**当且仅当** `W` 每项在同一趟腿上有**可现取的真读数／具名留痕**（`P10`）时，"内容层那一波"＝**已落地**；否则**未开工**」；**逐项的准入本体** ＝ 各行「出处」列。**同一趟腿** ＝ `~/tA73-work/legs/after`（＝现状腿，见件头）。

| # | `W` 成员（`dingrecon.md:98`） | 出处（件:行） | 现取读数（本席；`after` 腿 `grep -c`） | 判定 |
|---|---|---|---|---|
| ① | `PRECOND-LS-SESSION-DRIVER` | `P1-ls-callback-face-recon.md:85` | `[LSSESS]` **53 行**（`ctx`×3 ＋ `mgd`×25 ＋ `rx=OK`×25）；`distinct_ploc=3`／`distinct_para=25`／`rx_reject=0` | ✅ **满足**（本侧已成**重入方**：会话身份**在链上可认领**） |
| ② | `PRECOND-NO-TEXT-SOURCE` | `P1-layout-content-criteria.md:112` | `[TEXTSRC]` **50 行**（`mgd`×25 ＋ `rx=OK`×25）；`mism=0` **25/25**、`hash_match=1` **25/25**、逐字节对拍 | ✅ **满足**（「**字符序列**」半＝真入站；「`dcp`」半归 ⑤） |
| ③ | `PRECOND-NO-LINE-BREAKER` | `P1-layout-content-criteria.md:113` | `[LINEBREAK]` **50 行**（`mgd`×25 ＋ `rx=OK`×25）；`mono=1`／`first=1`／`cover=1` **25/25**、`mism=0` | ✅ **满足**（**射程**见 §1.1-③） |
| ④ | `PRECOND-NO-TEXT-PARA-IN-CHAIN` | `P1-layout-content-criteria.md:114` | `[PARACHAIN]` **50 行**（`mgd`×25 ＋ `rx=OK`×25）；`link=1`／`mism=0` **25/25**、`distinct_parah=25`／`distinct_page=21` | ✅ **满足**（与 ② **一一对应**，交集 25／25） |
| ⑤ | 契约 `C4`（`cp↔dcp` 宿主给定，本侧只校不算） | `P1-ls-provenance-contract.md:72` | `[CPDCMAP]` **50 行**（`mgd`×25 ＋ `rx=OK`×25）；`mism=0`／`pair_match=1` **25/25**、`off=0` | ✅ **满足**（**射程**见 §1.1-⑤） |
| ⑥ | `PRECOND-NEW-CALLBACK-FACE` | `P1-layout-content-criteria.md:111` | `[LSCBF]` **3 行**（`rx=OK`×3）；`slots=28`／`nonzero=26`／`min_nonzero=8/9`／`redef_nonzero=3`／`layok=1` | 🔴 **不满足（语义）**（**形式**满足；「面真被用于取内容」不满足 —— 件:行见 §1.1-⑥） |
| ⑦ | `C2`（LS 会话标识） | `P1-ls-provenance-contract.md:70` | `ploc` 半：`distinct_ploc=3` **可现取**（同 ①）；`plsrun` 半：**全仓无源** | 🔴 **不满足**（**只落 `ploc` 一半**；`plsrun` 一半**结构性不存在** —— 件:行见 §1.1-C2） |

- **现取佐证（同一权威件 `df27801beb222f05` ⇒ 同一趟腿）**：`before` 腿与 `after` 腿**只差权威 `.so`**（`before`＝`T-A72` 末件 `630cefb6c7bdf0f0`）；`before` 腿 `[LINEBREAK]` **0 行**（旧件无此面），其余 5 面已随各自增量上位。
- **计数核对（本席 `grep -c` 现取，`~/tA73-work/legs/after/app_g1.log`）**：`LSCBF=3`／`TEXTSRC=50`／`PARACHAIN=50`／`CPDCMAP=50`／`LSSESS=53`／`LINEBREAK=50`。

### §1.1 逐项「满足／不满足」的**件:行**证据与**射程**（🔴 防读宽）

- **①（满足）**：`T-A72` 载「`[LSSESS] rx=OK … state=BOUND` ×25」＋**会话数 3**＋**回调面指纹 3 枚**（同一会话内恒同值 ⇒ 可证伪）⇒ 「会话进入本侧台账且**按对象身份可认领**」有真读数；其**射程**（`P1-tail2-lssession-impl-report.md:25`）：「**进链 ≠ 排版** …… **不**主张『LS 引擎真用该会话排了该段』（**本移植绕过 LS 造型**）」。
- **②（满足）**：`T-A69` 载「`[TEXTSRC] mgd … mism=0 hash_match=1` ×25」⇒ 「**字符序列**可从托管入站、可逐段现取、可与托管真值**逐字节对拍**」有真读数；其**射程**（`P1-tail2-textsrc-impl-report.md:56-58`）：「『**字符源**』**这一半满足**，『**`dcp` 映射**』**那一半**归 `C4`；**入站 ≠ 排版** —— **不**填任何几何／行盒／`dcp` 区间，**不**解除 `W`」。
- **③（满足）**：`T-A73` 载「`[LINEBREAK] mgd … mono=1 first=1 cover=1 mism=0` ×25」⇒ 「**断点 `cp` 序列可寻址 ∧ 两条不变量逐段对拍有牙 ∧ 可两极化**」有真读数；其**射程**（`P1-tail2-linebreak-impl-report.md:59-63`）：「**行断器 ≠ 排版前进**（三腿四帧逐字节同 ⇒ **零像素位移**）；『**native 自己断行**』那一半**不满足**（断点 `dcp` 由**托管真排版**产出）；**软断行（按宽度换行）本侧推不出** ⇒ **不冒充**；**度量字段一个都不给**（`Info(k,i,3) == -1`，**无度量源**）」。⇒ **③满足的只是"断点集合可现取＋可对拍"这一半**。
- **④（满足）**：`T-A71` 载「`[PARACHAIN] mgd … state=2 sub=1 link=1 mism=0` ×25」＋与 `T-A69` **一一对应**（同一批 25 段：交集 25／25、只在 `T-A69` 0）⇒ 「文本段落**在链上可寻址** ∧ 五格（段身份／页／子轨／`cp` 域／源句柄）**逐段现取** ∧ **一一对应**」有真读数；其**射程**（`P1-tail2-parachain-impl-report.md:24`）：「**进链 ≠ 排版**」。
- **⑤（满足）**：`T-A70` 载「`[CPDCMAP] mgd … mism=0 pair_match=1 off=0` ×25」⇒ 契约 `C4` 的「**由宿主给定并留痕**」（`P1-ls-provenance-contract.md:72`／`:93` ④）与「**只校不算**」（校验单调／端点／双射／守恒／越界；`off` **取自宿主样本**）有真读数；其**射程**（`P1-tail2-c4-impl-report.md:56`）：「『**自洽性**』**这一半满足**，『**对真值**』**那一半不满足** —— 契约 §5 两条必红反腿 `(a)(b)`（偏移错一／跨段落复用同一 `plsrun` 表）**须外部 LS 真值 ⇒ 今天不跑**（标**随内容层那一波**）」。
- **⑥（🔴 不满足）**：**形式要件**（`P1-layout-content-criteria.md:111`：「要接**第二条回调面（30 槽）** ⇒ **须队长裁定另开一波**（含其 `ABI`／寿命／快照口径）」）**满足**；但 **`W` 的语义**（`P1-tail2-dingrecon.md` §3.2 第 1 条：「`LoCreateContext` 的 `ploc` 与文本段落 `nmp` **在本侧同一窗内可观测**」＋ 该面的用途＝**取内容**）**不满足**。**件:行（其作者自判，逐字）**：`build/MilBridge/P1-tail2-lscbf-impl-report.md:24`／`:190` —— 「`PRECOND-NEW-CALLBACK-FACE` 的**形式要件**……由本件**满足**；但……**语义**（"**面真被用于取内容**"）**不满足** —— 本侧**不是**这 28 槽的作者（全为**入站面**），`W` 合取**仍 `7/7` 未解除**」；`P1-tail2-linebreak-impl-report.md:260`（**最后一趟**在册判词）仍把 `PRECOND-NEW-CALLBACK-FACE`（**度量/回调面**）列为「**未解除**」。**且**：`InlineFormat`／`InlineDraw` **两槽不在两入参结构内**（`SRC_NONE`，**本侧不取、不冒充**）。
- **⑦ C2（🔴 不满足）**：契约 `C2`（`P1-ls-provenance-contract.md:70`）的形态是「`plsrun` 起点 **或** `LoCreateContext` 的 `ploc`」—— **`ploc` 一半本侧已有**（`T-A67` §3.3-1；`LoCreateContext`／`LoDestroyContext` 早在册真实现并导出）；但**另一半 `plsrun` 在本移植链上**结构性不存在**：`P1-ls-callback-face-recon.md:85` 判「**新增具名前置** `PRECOND-LS-SESSION-DRIVER` —— 一旦实现 LS，本侧要成为**重入方**」，而 `T-A72`／`T-A73`／`LSSESS`／`LINEBREAK` 三件（含各自 §7）**一致**把「`C2` 的 `plsrun` 那一半」列为**未解除**（`P1-tail2-lssession-impl-report.md:278`：「`C2` 的 `plsrun` 那一半**未解除**」）。⇒ **`C2` 整条不成立**。

### §1.2 计数核对（现取）

- `W` **满足**：**5**（①②③④⑤）；**不满足**：**2**（⑥、⑦`C2`）。
- 与**在册最末判词**一致：`P1-tail2-linebreak-impl-report.md:260`「`W` 余项 ＝ `C2`（`plsrun` 那一半）／`PRECOND-NEW-CALLBACK-FACE`（度量/回调面）**未解除**」⇒ **余项恰 2**，与本件现取**逐条相符**。

---

## §2 结论：可否判「已解除」

> **明确结论：`W` **不可判「已解除」**（＝**未解除**）。**

**为何（缺失项 ＋ 逐条理由）**：

1. **`⑥`**（`PRECOND-NEW-CALLBACK-FACE`）：**形式满足 ∧ 语义不满足** —— 「面**真被用于取内容**」这一语义要件**今天不成立**：本侧**不是**这 28 槽的作者（全为**入站面**），且 `InlineFormat`／`InlineDraw` **两槽未解**（不在两入参结构内）。⇒ 该面**可观测／可发调**，但**尚未承重内容**（其作者 `T-A68` 自判「`W` 合取**仍 `7/7` 未解除**」）。
2. **`C2`**：「`ploc` 一半**有** ∧ **`plsrun` 一半结构性不存在**」 —— `plsrun` 由 `LineServicesCallbacks` 分配（`P1-ls-provenance-contract.md:70`），而**本移植绕过 LS 造型**（`T-A72`／`T-A73` 载）⇒ 本侧**不在该会话内**、**也非作者** ⇒ 该半**不是"未做"，而是"无来源"**。⇒ `C2` 整条**不可成立**。
3. **形式条件（`dingrecon.md:98`）虽对 5 项成立，但不构成「已解除」**：`dingrecon.md:98` 的「已落地」判据**只管"每项有可现取真读数／具名留痕"**；而 5 个"满足"项**各自的在册判词都写明「≠排版前进／零像素位移」**（①②③④⑤ 的射程，见 §1.1）⇒ **`W` 的形式条件满足 ≠ 内容层"已落地成排版"**。🔴 **本条不把"形式满足"外推成"语义已解除"**（恒真断言族禁令，`P1`–`P10`）。
4. **具名缺失项**（消掉条件见 §4）：`MISS-C2-PLSRUN-HALF`／`MISS-CBF-SEMANTIC`／`MISS-METRICS-SOURCE`／`MISS-DWRITE-SCRIPT-ANALYSIS`。

⇒ 承派单 §① 第 2 条：**如实报停止**；**丁类 16 条一条不实施**。

---

## §3 丁类 16 条现状（为何仍不可诚实实施）

### 3.1 16/16 仍缺口（现取，两路独立）

- **现取命令**（本席）：`grep -cx <名> src/WpfGfx.Linux.Native/bin/exports.txt` ∧ `nm -D --defined-only … | awk '{print $3}' | grep -cx <名>`。
- **读数**：`Lo*` 12 ＋ 文本分析 4 ＝ **16 名，两路逐名皆为 `0`**（逐名见 §3.2 表；无一行例外）。⇒ `T-A65` 丁类 16 条**一条未动**（`T-A66` 的甲类 5 条与 `Lo*`／文本分析**无关**）。

### 3.2 逐族「真依赖」归并（承 `T-A67` §4.1／§4.2，本席现取复核其**缺口态**）

| 族 | 名 | 真依赖（根对象／源；件:行） | 本侧现态（现取） |
|---|---|---|---|
| `L1` `Lo*` | `LoAcquireBreakRecord`／`LoCloneBreakRecord`／`LoDisposeBreakRecord`／`LoDisposeLine`／`LoDisplayLine`／`LoEnumLine`／`LoRelievePenaltyResource` | 根对象＝**行**（`ploline`）或**断行记录**（`pBreakRec`）；**唯一创造者** `LoCreateLine`（`LineServices.cs:1419`）**本侧无源** | 缺口（0／0）；`win32_pts.c:4593` 排除注释逐字在内 |
| `L1` `Lo*` | `LoQueryLineCpPpoint`／`LoQueryLinePointPcp` | 根对象＝**行**；出参 `LsTextCell` 需**行内容** | 缺口（0／0） |
| `L1` `Lo*` | `LoCreateLine` | 出参 `LsLInfo`（22 字段**全度量**）＋`LsLineWidths`（7 字段）＋`maxDepth` ⇒ **真度量源** | 缺口（0／0）；**无测量源**（返 0 即「静默半通」） |
| `L1` `Lo*` | `LoCreateBreaks` | 出参 `LsBreaks`（断点集＋逐断点 `LsLInfo`）＝**排版产物** | 缺口（0／0） |
| `L1` `Lo*` | `LocbkGetObjectHandlerInfo` | **native 对象处理器**（`objectId < TextStore.ObjectId.MaxNative = 1`）⇒ 本侧**无 native 对象处理器** | 缺口（0／0） |
| `L2` 文本分析 | `CreateTextAnalysisSink`／`GetScriptAnalysisList`／`GetNumberSubstitutionList` | **DWrite 脚本分段／数字替换**：`TypefaceMap.cs:120-122` **方法组**传入 `TextAnalyzer.Itemize`，而 `Itemize` ＝ **`[PNSE · D 档]`**（`build/DirectWriteForwarder.Linux/ManagedSurface.cs:1120`／`:1128` `NotSupported.Throw<IList<Span>>(nameof(Itemize))`） | 缺口（0／0） |
| `L2` 文本分析 | `CreateTextAnalysisSource` | 入参**直接是 `char* text` ＋ `length`**（`LineServices.cs:1609-1618`）⇒ 须先把**内容源**接进链 ＋ 出参＝分析源接口 | 缺口（0／0） |

### 3.3 🔴 两条**独立**的"不可诚实实施"理由（任一条足矣）

1. **`W` ⊉ 丁类的真前置（`L1` 的度量源／`L2`）**：`T-A67` §4.3 现取判词（本席复核其**缺口态**无变）：「丁类 16 条**没有一条真依赖 `C2`/`C4` 本身** —— ① `C2` 的 `ploc` 一半本侧**已有**；② 4 条文本分析的真依赖是 `L2`」；`T-A73` §7 进一步把**度量源**（`LS-CB-M1` 的 `GetRunTextMetrics`／`GetRunCharWidths`）明标为「**越级项（须队长裁定）**……**本条未触碰**」。⇒ **即便 `W` 全绿**，丁类 16 条的**出参真值**（`LsLInfo`／`LsLineWidths`／`LsTextCell`／`LsBreaks`）**仍无源** ⇒ 实现即**伪造度量**（红 `P3`／`P8`）。
2. **LS 那条链在本移植已被 shim 替换 ⇒ 16 条无真腿可达**：`build/MilBridge/P1-tail2-hostline-recon.md:161` 现取：「**native LS 只在托管 `TextFormatter` 内部才被用到**（`TextFormatterContext.cs:113/:288/:354`）**而那一层已被 shim 替换**（生成物 `:692/723`）⇒ **在 native 侧重建 LS 不会给 `FsQueryLineList*` 多带来任何行盒**（它在托管侧已全有）」；同件 `:164` 判定「**不可取**（代价极高 ∧ 与本件现取的『行盒真源』不符）」。⇒ 丁类入口**无**现产品路径上的调用点 ⇒ **无法造出真腿 ＋ 无法两极化 ＋ 无法帧面成对** ⇒ **实现即不可验证**（并踩 `T-A67` §7-4 的 `NOINFO-DING-CALLSITE-REACHABILITY`）。
3. **降为"诚实拒绝 stub"不构成诚实增量**（承 `T-A67` §5.1-3，本席复核其现取依据仍在）：`LS` 入口的错误码域是 `LsErr`（`LineServices.cs` 起；非 `None` 即抛）；PTS 域的 `-10000` **不在** `LsErr` 枚举 ⇒ 用 `-10000` 冒充 LS 拒绝＝**假错误码**。

⇒ **丁类 16 条「可诚实实施者」现取 ＝ `0`**（**不是"懒得做"，而是"无源 ∧ 无真腿"**）。本件**如实划界**，**一条不导出、不 stub**（**不假成功**）。

---

## §4 具名缺失项 / `NOINFO`（逐条给"消掉条件"）

1. **`MISS-C2-PLSRUN-HALF`** —— `C2` 的 `plsrun` 那一半。**为何缺**：本移植**绕过 LS 造型**（`T-A72`／`T-A73` 载）⇒ `plsrun` 由 `LineServicesCallbacks` 分配，本侧**不在该会话内、也非作者** ⇒ **无来源**（`P1-ls-provenance-contract.md:70`：❌ **不能** ⇒ 只能**接收并保管**）。**消掉条件**：本侧成为**重入方**并真驱动 `Lo*` 引擎（`PRECOND-LS-SESSION-DRIVER` 的**结构版**，非本条的面版）。
2. **`MISS-CBF-SEMANTIC`** —— 第二条回调面的**语义**要件「面**真被用于取内容**」。**为何缺**：28 槽**全为入站面**（本侧**非作者**）；`InlineFormat`／`InlineDraw` **不在两入参结构内**。**消掉条件**：本侧成为该面的**作者侧**用法（真用面**取到**内容/度量），或补 `InlineFormat`／`InlineDraw` 的取法（经 `pfnGetObjectHandlerInfo` 的**处理器信息** ⇒ 须先有 native 对象处理器）。
3. **`MISS-METRICS-SOURCE`**（`L1` 的度量源）—— `LS-CB-M1` 的 `GetRunTextMetrics`／`GetRunCharWidths` **未接**。**为何缺**：`T-A73` §7 明标**越级项（须队长裁定）**。**消掉条件**：队长裁定另开一波接该度量面（其后 `LoCreateLine`／`LoCreateBreaks` 的**真几何**才可能有源）。
4. **`MISS-DWRITE-SCRIPT-ANALYSIS`**（`L2`）—— DWrite 脚本分段／数字替换。**为何缺**：4 条文本分析的**真前置**（`T-A67` §3.3-2 **新立**）**不落 `W` 任意一条**；且 `Itemize` ＝ `[PNSE · D 档]`（`ManagedSurface.cs:1128`）。**消掉条件**：DWrite 脚本分段（`AnalyzeScript`）在本移植可用，或经队长裁定另立其等价物。
5. **`NOINFO-DING-CALLSITE-REACHABILITY`**（承 `T-A67` §7-4）—— 16 条的**调用点是静态文本命中**；现产品路径上「**是否必不被走到**」未实测（本件据 `hostline-recon.md:161` 判"那层已被 shim 替换"）。**消掉条件**：一条**真装置腿** ＋ 逐入口 `entry=` 留痕。
6. **`NOINFO-C2-PLOC-ON-CHAIN`**（承 `T-A67` §7-5）—— 本侧**已有** `ploc`（`T-A72` 现取 `distinct_ploc=3`），但「托管是否真**驱动 `Lo*` 引擎**」仍无读数（`[LSSESS]` 只证「`LoCreateContext` 被调 ＋ 会话进链」）。**消掉条件**：一条腿的 `Lo*` 引擎调用留痕（非 `LoCreateContext` 一族）。

---

## §5 纪律与验收（现取）

- **门禁四件**（`>out 2>err; echo $?` 形态；**本趟零源码改动** ⇒ 与 `T-A73` 结账同值）：
  - `PTSGAP=PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=df27801beb222f05 exports=846 root=/home/links-dev/netTest/GitProj/WPFOnLinux`（rc=0）；`W66PRE16 live=bf6b683d94549087`；`PTSGAP_FRONTIER_STATE=NAMED frontier=FsQueryTextDetails`。
  - `nm -D --defined-only … ＝ exports.txt ＝ **846**`（逐名 `diff` **零差异** ⇒ `nm==exports`）。
  - `PTS_GUARD=PASS legs=2/2 fails=- cannot=-`／`PTS_COLORANCHOR=PASS k=24 hits=3`（`GhostWhite=9794 Beige=910 DarkGreen=44 LightGoldenrodYellow=5830`；`k=23` 具名 `NOINFO`：该页无锚）／`PTS_ENFE=PASS total=0`（**未回退**；现取自现状腿 `~/tA73-work/legs/after`）。
  - `PTSGAP` 逐字段 `ops`／`impl` **＝ 42／42**，与**实施条数 `k=0`** **一致**（`ops`／`impl` **一字未动** ⇒ 与派单 §③ 第 3 条相容）。
- 🔴 **`P8`**：本件**未用**"两样本一致"类证据；一切读数**来自读取**（`grep`／`nm`／`sha256sum`／只读牙）。
- 🔴 **`P9`**：本件**不**判「内容没有源」（源在**宿主侧**，`P1-layout-content-criteria.md:146`）；只判「**取它要 `L1`／`L2`**」。
- 🔴 **`P10`**：每条否定附**射程**（件＋行号＋现取命令）。
- 🔴 **硬边界**：**永不假成功／零假值** —— 本趟**零实现、零 stub、零导出**；`ops`／`impl`／`exports` **逐字未动**（这**正是**「判未解除 ⇒ 报停止」的落点）。
- **未跑整趟 `verify-all`**（照派单）；本节所有"不得读成绿"的口径照在册红榜 `P1`–`P10`。

`P1-TAIL2-DINGIMPL 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ f6eb011fe1f4ddea（末行＝本行）`

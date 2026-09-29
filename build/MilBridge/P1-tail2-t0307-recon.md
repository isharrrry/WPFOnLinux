# P1-tail2 `TASK-0307` 侦察（`FsQuerySubtrackParaList`（`S-2b` 族）＋ LS 溯源桥）—— 只读侦察 ＋ 判据预登记

- **读时**：`2026-09-30T06:41+0800`（本席 `tG0` 现取）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=5315129`（`git ls-remote` 同值）。
- **件指纹（现取，`sha256` 前 16 位）**：`src/WpfGfx.Linux.Native/src/win32_pts.c`＝`57a80e0bb51d17ea`（4529 行）｜`bin/libwpfwin32.so`＝`26da177686acb1f0`（gitignored）｜`bin/exports.txt`＝`669` 行｜`PtsHelper.cs`＝`f2ed9552e983fed1`｜`ContainerParaClient.cs`＝`0d2e6aa79fdc035a`｜`Pts.cs`＝`1a8575a18767a956`｜`P1-ptsname-result.md`＝`b8f214e5d01d5225`｜`P1-ls-provenance-contract.md`＝`b57927c2c229629d`｜`P1-ls-provenance-recon.md`＝`cae43cb98e0926b1`｜`docs/ROUTES.md`＝`01d4b1559d5bee1b`。
- **边界（照 T-G0 ②）**：只读；除本件外**未改任何仓内文件**；**未构建／未跑腿／未占显示位／未跑 `verify-all`／未跑 `static-jaws-check.sh`**；大件只用 `wc/head/tail/grep -c`；未 `git add/commit/push`。
- **行号纪律**：下表所有行号**仅本次有效**（内容锚原文一并给出，供下一位现取复核）。

---

## §0 前提核对（一条声明不符，先报）

| 声明（出处） | 现取 | 结论 |
|---|---|---|
| T-G0 ①：「在**前置总册 `build/MilBridge/P1-ptsname-result.md`** … 里现取 `PRECOND-PARADESC-SOURCE-MISSING`」 | `grep -c 'PRECOND-PARADESC-SOURCE-MISSING' build/MilBridge/P1-ptsname-result.md` ⇒ **`0`**；该件内 `PARADESC` 5 处**全是** `FSPARADESCRIPTION`（`:447/:489/:503/:647/:730`），**无该前置名** | **前提不符**：该前置**未登记**在裁定总册；在册实例在**四件 consume 报告 ＋ `HANDOFF` ＋ `ROUTES`**（§1 给行号）。总册只在 `§9` 承担"未做/边界"，不是前置登记处 |
| T-G0 ①：`PRECOND-LS-PROVENANCE-BRIDGE` 在 `P1-ls-provenance-contract.md` 里现取 | `:11`（立名）／`:60`（收口判词）／`:154`（本席判词）**三处**齐 | **前提成立**（§1） |

---

## §1 两条 `PRECOND-*` 现取状态（件:行 ＋ 原文）

### 1.1 `PRECOND-PARADESC-SOURCE-MISSING`（**收窄为 `scope=subtrack-path`**，未解除）

| 出处 | 现取定位 | 原文（整行取，仅本次有效） |
|---|---|---|
| 判据件 | `build/MilBridge/P1-host-consume-route-criteria.md:183` | `- **新前置入册**：**\`PRECOND-PARADESC-SOURCE-MISSING\`**（**段落描述数组 \`arrayParaDesc\` 无源**：唯一填写者 \`PTS.FsQuerySubtrackParaList\` native 未实现；射程＝\`PtsHelper.cs:174-180\` 那条 \`rcPara.dv\` 计算；粒度＝单次 \`ArrangeParaList\` 调用）。` |
| 判据件（收窄） | 同件 `:238`（dated 补记） | `## ⏪ \`t207\`（A-2）dated 补记 · 前置**加射程**：\`PRECOND-PARADESC-SOURCE-MISSING\` **\`scope=subtrack-path\`**（读时 \`2026-09-29T23:25:07+0800\`；**只增不改**、删行数 0）` |
| 另一判据件 | `build/MilBridge/P1-lm-consume-witness-criteria.md:153` ＋ `:208`（同形） | 同 `:183` 逐字；`:208` 同形 dated 补记 |
| 载体件 | `build/MilBridge/P1-lm-consume2-report.md:91` ＋ `:146`（同形） | 同 `:183` 逐字；`:146` 同形 dated 补记 |
| 分路径裁决 | `build/MilBridge/P1-lm-consume3-verify.md:5`（一句裁决） | `> **裁决（一句）：分路径裁决 —— \`t198\` 的驳回在 \`track-path\` 上成立；\`t195\` 的 \`W-1\` 在 \`track-path\` 上被推翻、在 \`subtrack-path\` 上成立。** 故 **\`PRECOND-PARADESC-SOURCE-MISSING\` 应收窄为 \`scope=subtrack-path(ContainerParaClient.cs:70→:72)\`，不覆盖 \`track-path(PtsHelper.cs:134→:137)\`** ⇒ \`t198\` §8.3 的提议**成立**；\`(甲)\` **不回退**。` |
| 交接包 | `build/MilBridge/P1-HANDOFF-20260929.md:39`（§5 硬阻塞） | `- \`PRECOND-PARADESC-SOURCE-MISSING\`／\`scope=subtrack-path\`：需实现 \`FsQuerySubtrackParaList\`（属 \`S-2b\` 一族，本波判不做）。` |
| 路线图 | `docs/ROUTES.md:314`（`TASK-0307` 目标行） | `│       ├─ 目标：解 \`PRECOND-PARADESC-SOURCE-MISSING（scope=subtrack-path）\` 与 \`PRECOND-LS-PROVENANCE-BRIDGE\`。` |

**状态判词（现取）**：**未解除**。四要件齐（授权出处＝`t195` 判词 `W-1`／射程＝`PtsHelper.cs:174-180` 那条 `rcPara.dv` 计算，**限 `subtrack-path`**／粒度＝单次 `ArrangeParaList` 调用／**逐入口**＝`FsQuerySubtrackParaList` native **未实现**）。**实测收紧项**：运行期 13 腿 26 行 `[FSPARALIST-FILL]` 的 `entry=` **26/26 ＝ `FsQueryTrackParaList`**、`FsQuerySubtrackParaList` **0 行** ⇒ 宿主这趟**走的是 track-path**（subtrack 路未被行使）。`t195` 的 `W-1` 在 track-path 上**已被 `t206` 推翻**（`arrayParaDesc` 是形参、调用点恰两处）—— 引用时必须按路径读。

### 1.2 `PRECOND-LS-PROVENANCE-BRIDGE`（未解除，且属"内容层那一波"）

| 出处 | 现取定位 | 原文（整行取，仅本次有效） |
|---|---|---|
| 契约草案（立名） | `build/MilBridge/P1-ls-provenance-contract.md:11` | `- 来源件：\`t190\` 载体 \`build/MilBridge/P1-ls-provenance-recon.md\`（167 行／自证 \`27a1ea496c79f08f\`，**本席未独立复算其内部读数**）——它立 **\`PRECOND-LS-PROVENANCE-BRIDGE\`** 并给出 C1–C4 四列。` |
| 契约草案（收口） | 同件 `:60` | `**⇒ 收口判词（写死）：5 件共现里**没有任何一件**把 LS 侧的量与 PTS 的 \`dcp\`／\`nmp\` 连起来；5 件全部是**同名不同义**（LS 的 \`dcp\` 系＝dnode/子行/run 的字符计数与依赖计数；PTS 的 \`dcp\`＝文档字符位置）。⇒ \`NOINFO-COOCURRENCE-SEMANTICS\` **解除**（已逐件核完），其结论**并入** \`PRECOND-LS-PROVENANCE-BRIDGE\`（桥仍缺，且现在**连"看起来像桥"的候选也被排除**）。**` |
| 契约草案（判词） | 同件 `:154` | `**判词（本席）**：① **C3 口径修正（本件最重要的一条）**：\`TextStore\` 只有 **2 个构造点**，**\`lscpFirstValue\` 不恒为 0** …… ③ **责任方表**：C1 宿主（本侧可校值、不可校语义）；**C2 今天不存在，须新立**；C3 托管侧**已有**（构造时一次绑定、之后只读）；**C4 今天不存在，须新立**，且本侧**只能复算校验、不得自算**。④ **两条必红反腿已写死**（偏移错一／跨段复用同一 \`plsrun\` 表），并**如实标注今天都不可跑**（随内容层那一波），**不得**因此判绿或判红。⑤ 契约本体（objective／六条合取 acceptance／verify／inScope／outOfScope／粒度＝单段落）已成形，**本波不做**。` |
| 来源件（立名） | `build/MilBridge/P1-ls-provenance-recon.md:99` | `- **\`PRECOND-LS-PROVENANCE-BRIDGE\`**（映射件本体）：\`plsrun\`/\`lscp\` ↔ \`nmp\`/\`dcp\` 的**运行期对应关系与责任方**在仓内**不存在**，须由"内容层那一波"**新立**；且**本侧不能作为作者**，只能**保管并复算**。` |

**状态判词（现取）**：**未解除**，且**今天为时过早** —— C2（LS 会话标识）与 C4（`cp↔dcp` 偏移）**今天不存在、须新立**，须"内容层那一波"（先有 LS 会话 ＋ 文本段落进链，`t185` 已列为越级）；本侧**不得自算 `dcp`／`plsrun`**。两条必红反腿**今天都不可跑**（无 LS 会话、本侧无 `dcp` 值）。

---

## §2 两侧落点表 ＋ 「钥匙 vs 其后」判定（照裁定二十六 (a) 体例）

### 2.1 落点表

| 侧 | 落点（现取定位，仅本次有效） | 状态 | 原文 |
|---|---|---|---|
| **native**（靶心） | `src/WpfGfx.Linux.Native/src/win32_pts.c:3803`（**唯一命中，且是注释**） | **未实现**：`grep -c` ＝ **1**（注释）；`nm -D --defined-only` ＝ **0**；`exports` 无该名 | `与 \`FsQuerySubtrackParaList\`（\`PtsHelper.cs:633\`），二者都属 **(b)**、**尚未实现**）。` |
| native（**钥匙**） | 同件 `:3802`（**唯一命中，且是注释**） | **未实现**：`grep -c` ＝ **1**（注释）；`nm -D` ＝ **0** | `/* 🔴 **下游接受者：本件无**（判据 §5.5 的在册接受者＝ \`FsQuerySubtrackDetails\`（\`:271\`）` |
| native（track-path 对照，**已实现**） | 同件 `:3603` `int FsQueryTrackParaList(void *pfscontext, void *pTrack, int cParas, void *rgParaDesc, int *cParaDesc)` | **已实现/已导出**：`nm -D` ＝ **1** | 打印点 `:3843` `[FSPARALIST-FILL] rc=0 reason=ok entry=FsQueryTrackParaList …` |
| **托管**（调用点） | `upstream/wpf/…/PtsHost/PtsHelper.cs:633` | 存在，**今天不可达** | `                PTS.Validate(PTS.FsQuerySubtrackParaList(ptsContext.Context, subtrack, subtrackDetails.cParas,` |
| 托管（所属函数） | 同件 `:623` `internal static unsafe void ParaListFromSubtrack(`（分配数组 `:629`、断言 `:636`） | 存在 | `:629` `arrayParaDesc = new PTS.FSPARADESCRIPTION [subtrackDetails.cParas];` |
| 托管（声明） | `upstream/wpf/…/PtsHost/Pts.cs:3742` `internal static extern unsafe int FsQuerySubtrackParaList(` | 存在 | `:3744` `IntPtr pSubTrack,                  // IN:  ptr to subtrack` |
| 托管（唯一调用者） | `upstream/wpf/…/PtsHost/ContainerParaClient.cs:70` → `:72` | 存在，**今天不可达** | `:72` `                PtsHelper.ArrangeParaList(PtsContext, subtrackDetails.fsrc, arrayParaDesc, fswdirSubtrack);` |

### 2.2 「钥匙 vs 其后」判定（**靶心 ＝ 其后，不是钥匙**）

**subtrack 路径的现取链（逐跳，仅本次有效）**：
`ContainerParaClient.cs:41 OnArrange` → **`:47 PTS.FsQuerySubtrackDetails(PtsContext.Context, _paraHandle, out subtrackDetails)`** → `:66 if (subtrackDetails.cParas != 0)`（**以 `cParas` 门控**）→ `:70 ParaListFromSubtrack` → **`PtsHelper.cs:633 FsQuerySubtrackParaList`** → `:72 ArrangeParaList`（读描述符 `dvrUsed/dvrTopSpace`，见 §3）。
另一 body `ContainerParaClient.cs:271 FsQuerySubtrackDetails`（同件 `:268` `Invariant.Assert` 之后**第一个实招**）→ `:277` 以 `cParas` 门控 → `:283 ParaListFromSubtrack` → `PtsHelper.cs:633` → `:289`（`HandleToObject(arrayParaDesc[i].pfsparaclient)`）。

**判词（照裁定二十六 (a) 体例）**：
- **钥匙 ＝ `FsQuerySubtrackDetails`**（`ContainerParaClient.cs:47`／`:271`）：它是该 body 里 `Assert` 之后**第一个实招**，且**以 `cParas` 门控** `:70`/`:283`；**它没通，`FsQuerySubtrackParaList` 一次都不会被调**。现取 `nm -D` ＝ **0** ⇒ 运行期首断点在它（`app-wit1.log:678/:684` 整行 ENFE，引自 `t195` 载体，**未独立复算**）。
- **其后 ＝ `FsQuerySubtrackParaList`（本任务靶心）**：被 `cParas` 门控（`:66`/`:277`），且**在钥匙下游**。⇒ **只补"其后"＝补死码**（宿主在钥匙处已被缺符号阻断），这正是裁定二十四 (a)「**别再撞一次**」与裁定二十六 (a)「分清钥匙与其后」要防的形态。
- **再上游（更根本）**：`LM-1`（本侧段账）是 `cParas` 与几何的**唯一上游源**（`P1-layout-model-criteria.md` §5／§6 现取：顺序＝**段账 → `cParas` → `FsQuerySubtrackParaList` → 消费者**）；无段账 ⇒ `cParas` 无真值（`t163` 判"诚实源在引擎侧"）。

---

## §3 `LM-1` 判 `7/8 PARTIAL` 第 4 条「宿主侧消费」缺口现取（`PtsHelper.cs:177` 链）

**第 4 条 ＝「消费者侧走过且 `rcPara.dv > 0`」**（`P1-layout-model-report.md`／`t181`：8 条合取**过了 7 条**，第 4 条记 `NOINFO` ⇒ `S-2a` **维持 7/8 `PARTIAL`**，**不写 8/8**）。

**现取链（`sha16 f2ed9552e983fed1`，整行取，仅本次有效）**：
```
145:        internal static void ArrangeParaList(
148:            PTS.FSPARADESCRIPTION [] arrayParaDesc,
155:            for (int index = 0; index < arrayParaDesc.Length; index++)
158:                BaseParaClient paraClient = ptsContext.HandleToObject(arrayParaDesc[index].pfsparaclient) as BaseParaClient;
174:                int dvrTopSpace = arrayParaDesc[index].dvrTopSpace;
177:                rcPara.dv = arrayParaDesc[index].dvrUsed - dvrTopSpace;
179:                paraClient.Arrange(arrayParaDesc[index].pfspara, rcPara, dvrTopSpace, fswdirTrack);
```
- **`arrayParaDesc` 是形参**（`:148`），**调用点恰两处**（`t206` 分路径裁决，同行数已现取复核）：`PtsHelper.cs:137`（数组来自 `:134 ParaListFromTrack(… out arrayParaDesc)` → **`:614 FsQueryTrackParaList`，已实现**）与 `ContainerParaClient.cs:72`（数组来自 `:70 ParaListFromSubtrack` → **`:633 FsQuerySubtrackParaList`，未实现**）。
- ⇒ **`subtrack-path` 上 `:177` 的两个操作数（`arrayParaDesc[index].dvrUsed`／`.dvrTopSpace`）无源**（唯一填写者未实现）⇒ **`:174-180` 今天结构性不可达** ⇒ **第 4 条在 `subtrack-path` 上不可判**（`NOINFO`）。
- **零判别力警告（引用纪律，见 `HANDOFF §5`／`R-4`）**：`t198` 写的描述符值**恒为模型常量**（`seg_h=16`／`top_sp=0`）⇒ **别把"算术成立"读成"内容被消费"**；即便将来走到 `:177`，`dvrUsed=16 / dvrTopSpace=0` 也**不能**支撑"整页排版成功"。
- **`t195` 的原始 `W-1`（"唯一填写者＝`:633`"）在 `track-path` 上已被 `t206` 推翻**（`arrayParaDesc` 按调用点服务两个数组）—— 引用时**必须**按路径读；`subtrack-path` 上该陈述**仍成立**。

---

## §4 判据预登记草案（供 `TASK-0307` 实现件照抄；≥3 条可证伪 ＋ 反极性）

> 纪律前置（照既有在册四要件）：**授权出处 ＋ 射程 ＋ 粒度 ＋ 逐入口状态**；每条读数带**纪律 33 格 ＋ 探针闸状态**；**绿只准**读成「native 把托管产出、持有期内有效的句柄交给列表的消费者，且消费者解析到**同一对象**」，**不得**读成"段落模型已成／排版打通／`pfsparaclient` 可用／`TASK-0007` 可绿"。

| # | 判据（可证伪） | 反极性（必红腿） |
|---|---|---|
| **C1** | **钥匙先通**：`.so` 导出面 `nm -D \| grep -c FsQuerySubtrackDetails` **≥1**，且运行期 `[HC-UNHANDLED]`/ENFE 面该名**归零**（t161 现取：native **0 命中**、封送阶段抛 ENFE、`PTS.Validate` 根本不执行）。 | **只补"其后"不补钥匙** ⇒ 真腿仍在 `ContainerParaClient.cs:47`/`:271` 抛 ENFE ⇒ **必红**（这是当前实测形态）。 |
| **C2** | **靶心已进导出面**：`nm -D \| grep -c FsQuerySubtrackParaList` **≥1**，`nm` 与 `exports.txt` 行数**相等**、逐名无消失（照裁定二十三 ⑤）。 | 未导出 ⇒ `[FSQSTD]` 0 行 ⇒ **必红**。 |
| **C3** | **`cParas` ＝ 托管真值（引擎侧记账，非回调槽）**：`rc=0` 时 `cParas` 与引擎侧驱动计数一致（`t163`：源在引擎侧；`PtsHelper.cs:636` `Assert(cParas == paraCount)` 会当场炸）。 | **拿 `nlines`／`nftn`／常数冒充 `cParas`** ⇒ `Assert` 炸 或 `cParas=0` 走叶子分支静默丢内容 ⇒ **必红**（`P8` 恒绿陷阱）。 |
| **C4** | **零假值/诚实**：返回非零**必留痕**（`[FS_PAGE_GAP]` 具名 `reason=`）＋**失败必清出参**（`*cParaDesc=0`、数组一字不写）；**禁静默 stub**（照裁定二十三 ①：留痕做在 native 侧）。 | **静默 stub**（返 `-10000` 但无痕、出参未清）⇒ 与"真 0 次"不可分 ⇒ **必红**。 |
| **C5** | **句柄身份＝可认领来源证据**：`pfspara`／`pfsparaclient` 与该对象来源（本侧对象字段地址，或与**同 run** 产出行同值）**对得上**；**不得**靠 `rc`／**不得**靠数值形态（`t161` ABA 反腿证 `rc` 无判别力；句柄是**表下标**）。 | 伪值 `0x1000`（`Invalid object handle.` `PtsContext.cs:247`，T1）／伪 `0x2`（`Handle has been already released.` `:248`，T2）／栈地址 ⇒ **`FailFast` 不可捕获** ⇒ **必红**（按 T1/T2/T3 分类点名）。 |
| **C6** | **`subtrack-path` 真被行使**：真腿日志出现 `entry=FsQuerySubtrackParaList` 的 `[FSPARALIST-FILL]` 行（**而非** `FsQueryTrackParaList`）。 | 26/26 仍是 `entry=FsQueryTrackParaList`（**当前实测形态**）⇒ 该路未被行使 ⇒ **必红**。 |
| **C7** | **窗内外两腿**：`W-1` 窗内／`W-2` 窗外**各一腿**；单腿只能 `NOINFO`（照 `t158` ④）。 | 只有单腿 ⇒ **不许判绿**。 |
| **C8** | **LS 溯源桥（属于"内容层那一波"，本波不可跑）**：锚点表 C1–C4 责任方齐 ＋ (a) **偏移错一 ±1 必红**、(b) **跨段复用同一 `plsrun` 表必红**（`P1-ls-provenance-contract.md` §5）。 | 两条反腿**今天都不可跑** ⇒ **不得**因"无读数"判绿或判红（**"无读数" ≠ "读数相同"**）。 |

**判词粒度（写死）**：C1–C6 为**单次调用／单入口**粒度；"整腿／整批"须三样齐备（真实页构造窗内 `calls>0` ＋ 消费者侧计数 ＋ 页面几何非空）；**帧面类要素一律带 `frame-determinism=NOINFO`**（冻结令未解）。

---

## §5 结论：**本波不做** ＋ 具名前置 ＋ 若做的最小可行第一步

### 5.1 判「本波不做」（据以下五条现取理由）

1. **靶心是"其后"，钥匙未通**：靶心 `FsQuerySubtrackParaList` 被 `cParas` 门控（`:66`/`:277`），钥匙 `FsQuerySubtrackDetails` **native 未实现**（`nm -D` ＝ **0**）⇒ 补其后＝**死码**，真腿会在钥匙处先抛 ENFE（`t161`/`t195` 现取）。
2. **属 `S-2b`（内容层）一族**：`HANDOFF §5` 现取「`S-2b`（内容层）判**本波不做**」；且 **`PRECOND-NO-LAYOUT-CONTENT-MODEL` 成立**（`t181`：无内容/行盒模型 ⇒ `S-2` 只能 `NOINFO`）。
3. **`PRECOND-LS-PROVENANCE-BRIDGE` 是草案、本波不做**：C2/C4「今天不存在、须新立」，须"内容层那一波"（先有 LS 会话 ＋ 文本段落进链）。
4. **托管侧协作者今天无落点**：`PtsHelper`／`ContainerParaClient` **按上游原样编译**（`csproj` 的 `<Compile Remove>` **不含**二者，`t184` 现取）⇒ 本波要动 `build/PresentationFramework.Linux/**` 的"托管侧协作者"（加只读打印／替身件）**无既有落点**，须先扩写域（`csproj`＋`reapply-patches.py`）⇒ 属 `PRECOND-HOST-CONSUME-OBSERVATORY-OUT-OF-DOMAIN`／`PRECOND-NO-MANAGED-SIDE-WRITER`。
5. **帧面冻结令未解**：`PRECOND-FRAME-DETERMINISM` **仍未满足**（裁定四十二 (b)）⇒ 任何"排版结论"类读数不可判，**相位位不得翻**。

### 5.2 「若不改产品，本波能做到哪一步」（具名前置）

**上限 ＝ 本侦察载体 ＋ 判据预登记（本件即此上限）**，**不改产品**能得到的**全部**是：① 两条前置的现取状态（§1）；② 落点表与钥匙/其后判定（§2）；③ 第 4 条缺口现取（§3）；④ 判据预登记草案（§4）。**不改产品 ⇒ 无法**解除任何一条前置。

**具名前置（未解除，逐条给射程）**：

| 前置 | 射程 | 状态／归属 |
|---|---|---|
| `PRECOND-PARADESC-SOURCE-MISSING`（`scope=subtrack-path`） | `PtsHelper.cs:174-180` 那条 `rcPara.dv` 计算；粒度＝单次 `ArrangeParaList`；逐入口＝`FsQuerySubtrackParaList` **未实现** | **未解除**；需 `S-2b` 内容层 |
| **钥匙未实现**（新，具名）`FsQuerySubtrackDetails` | `ContainerParaClient.cs:47`/`:271`；native `nm -D`＝0 | **未解除**（"其后"未通的**直接原因**） |
| `PRECOND-LS-PROVENANCE-BRIDGE` | 锚点表 C1–C4；粒度＝**单段落** | **未解除**；须"内容层那一波"新立 |
| `PRECOND-HOST-CONSUME-OBSERVATORY-OUT-OF-DOMAIN` ＋ `PRECOND-NO-MANAGED-SIDE-WRITER` | 托管侧 `.cs`；粒度＝单次 `ArrangeParaList` | **未解除**（托管侧协作者无落点） |
| `PRECOND-FRAME-DETERMINISM` | `fr_sha` 类要件（`N1①`/`N3`/`N4`/`in_empty_set`） | **未满足**（冻结令维持） |

### 5.3 若日后做 —— 最小可行第一步（**本波不做，仅登记供排期**）

**先补钥匙、再补靶心，同趟订清收尾同侪**（照裁定二十六 (a)／裁定十四「`create` 真了 ⇒ 收尾同侪必须同趟给」）：
1. **第一步 ＝ 实现「钥匙」`FsQuerySubtrackDetails`**（＋**同趟查清其销毁/收尾路径上还会撞谁**，别撞一次）；使运行期首次能走过 `ContainerParaClient.cs:47`/`:271`。
2. 同趟把 `FsQuerySubtrackParaList` 补为**诚实 stub**（导出＋失败可读＋清出参＋留痕，裁定二十三 ①②），**不宣布排版成功**（`S-2b` 越级本波不做）。
3. **判据先写（§4）→ 实现 → 独立复核**；LS 桥（C8）**随"内容层那一波"**，不得抢跑。

---

## §6 边界与 `NOINFO`（如实划界）

1. **未跑**构建／腿／整趟 `verify-all`／`static-jaws-check.sh`（照 T-G0 ②）；未占显示位；未 `git add/commit/push`；唯一写入＝本件。
2. **前提不符（如实记）**：`PRECOND-PARADESC-SOURCE-MISSING` **不在** `P1-ptsname-result.md`（`grep -c` ＝ **0**）⇒ 该前置的"总册出处"**今天不存在**，在册实例在四件 consume 报告 ＋ `HANDOFF` ＋ `ROUTES`（§1）。**这不是本件能修的**（判据件写者域）。
3. **`NOINFO`（逐条给消掉条件）**：① `subtrack-path` 运行期真腿读数（**今天结构性不可达** ⇒ 取不到）；② `pfspara` 在现件真值（本件未跑腿；`win32_pts.c` 现代 `pfspara` 由本侧对象字段填，`:3809-3810` `dp->fsp_para_val = para_val`，但**未独立复算**其真值）；③ LS 桥运行期实例（本波不可跑）。
4. **引他人读数（带代际，标"未独立复算"）**：`t161`／`t185`／`t191`／`t195`／`t206`／`t207` 与本波在册载体读数均**引自其载体**；本件**自算**的只有 §1 的 `grep -c`／`nm -D`／`exports` 计数、§2／§3 的整行现取与件指纹。
5. **未独立复算**：`t195` 载体引的 `app-wit1.log:678/:684` 整行 ENFE 未复算（本件未跑腿）；.so 现取 `26da177686acb1f0` 与 `HANDOFF §2` 同值。

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-t0307-recon.md | sha256sum | cut -c1-16`）= `0a101e8582fb5a52`

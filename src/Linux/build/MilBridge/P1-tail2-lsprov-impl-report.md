# `P1-tail2` · `T-A63` · `TASK-0307`：**LS 溯源桥 ＋ `pfsparaclient` 来源**（`PRECOND-LS-PROVENANCE-BRIDGE`／`PRECOND-PARADESC-SOURCE-MISSING(scope=subtrack-path)`）—— 实现报告（**判决：`subtrack-path` 的 `pfsparaclient` 来源**已接线且在跑**（前增量落地）—— 本趟把 `t158` 的**消费者判据**同形引到 `subtrack-path`（`[FSQSPL-CONSUME]` 观测行 ＋ 只读来源证据核对）＋ 加**「拆接线」反腿闸** `WPF_PTS_QSPL_PROV`（缺省开）⇒ **正/反腿成对现取**（正腿 `PTS_GUARD=PASS`／`PTS_COLORANCHOR=PASS hits=3`／`consume_ok=20378 consume_bad=0`；反腿 `=0` ⇒ `PTS_GUARD=FAIL`／`hits=0`／两页帧回空态集成员）⇒ **该来源承重**；**零回归**（改前/改后三帧逐字节 `AE=0`、症状门逐格同）；**导出面一字未动**（`nm==exports==718`）；`PTSGAP/DEFREG/REPORTID/HANDOFF_MV` rc=0。🔴 **两条前置仍 `PARTIAL`（如实划界，不假成功）**：`PRECOND-LS-PROVENANCE-BRIDGE` 的 C2/C4 **今天不存在**（须"内容层那一波"新立）；`PRECOND-PARADESC-SOURCE-MISSING` 的**承重几何**在 `subtrack-path` 上**仍无源**）

- **读时**：`2026-10-01T18:2x–18:4x+0800`（本席现取；各条另注）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`（**未 `git add/commit/push`**）。
- **改前件备份（仓外 `~/tA63-work/bak/`，`cp -p`，取在**任何写之前**）**：`win32_pts.c`（`2b8142ced5b68b76`／670589 B）／`bin/exports.txt`（`20b6d9aa3125bbc4`）／`bin/libwpfwin32.so`（`327dcce237e03e1f`／490072 B）／`tools/pts-gap-decl.txt`（`5965cc3e9ed89498`）。
- **写域（逐件）**：`src/WpfGfx.Linux.Native/src/win32_pts.c`（**只在 `FsQuerySubtrackParaList` 内**：加只读来源证据核对 `wpf_pts_prov_lookup` ＋ 3 只读计数 ＋ `[FSQSPL-CONSUME]` 观测行 ＋ `WPF_PTS_QSPL_PROV` 反腿闸）／`src/WpfGfx.Linux.Native/bin/exports.txt`（**构建重产**，非手改；**行数未变 718**）／`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（DECL 行 `so16` 跟权威件换 ＋ 只增一段 `T-A63` 重锚）／**复述位现值位**（`docs/ROUTES.md` `TASK-0307` 行加一条 dated 结账；`build/MilBridge/HANDOFF-NEXT.md` 文件尾机器值契约 `cell=#1／#3` 追写）／**新建载体** 本件。
- **未改**（如实体例）：`build/PresentationFramework.Linux/reapply-patches.py`（生成器**一字未动**——本增量**全在 native**，**零托管改动**）；`docs/WAVE66-PREREGISTRATION.md`（冻证据 `w66pre16=bf6b683d94549087` 未动）；在册 `evidence/**`。
- **黑名单遵守**：未动 `build/MilBridge/tools/**`（**只读跑**判据件）／`verify-all.sh`／`build/close-wave.sh`／`build/shims/**`／`upstream/**`（只读）；**未跑**整趟 `verify-all`；未改相位位；未 `git add/commit/push`。
- **重活**：**2 趟 native 构建**（改后 1 ＋ 重取 1）＋ **3 趟跑器**（共 **6 条腿**：`before`／`after-pos`／`after-neg` 各 2 条），全走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- <cmd>`（逐趟 `HEAVYSLOT=RELEASED rc=0`）；进程只按 PID；显示位只用空闲 `:231`（逐趟 `DISPLAY_PICK :231`）；禁 `sleep` 轮询；写前 `cp -p`；`temp+rename`；模式守恒。
- **口径**：一切读数**本席现取**（`sha256sum`／`nm -D --defined-only`／`diff`／`grep -c`／`python3`＋`PIL` 自算逐像素 `AE`／只读跑 `bash build/MilBridge/tools/{pts-gap-count-check,pts-pages-guard,defect-registry-check,report-id-domain-check,handoff-machine-values-check}.sh`）。凡引他件处一并标注。

---

## §0 结论速览（自包含）

1. 🔴 **两条前置逐条现取：均仍 `PARTIAL`（不假成功）** —— `PRECOND-LS-PROVENANCE-BRIDGE`（C1–C4）：**C1 有源（本侧可校值）／C3 托管侧已有（构造时一次绑定）／C2＋C4 今天不存在、须"内容层那一波"新立**；`PRECOND-PARADESC-SOURCE-MISSING(scope=subtrack-path)`：**数组来源已闭**（`FsQuerySubtrackParaList` 真填 `pfspara`／`pfsparaclient`／`nmp` ＋ 置 `cParaDesc`），**但 `:177` 的两个承重几何操作数在 `subtrack-path` 上仍无源**（逐条 `NOINFO-SUBTRACK-PARA-GEOMETRY`）。逐条状态与件:行见 §1／§2。
2. ✅ **`subtrack-path` 的 `pfsparaclient` 来源＝托管回调产出（前增量落地，本趟现取复核）**：`win32_pts.c` 的 `FsQuerySubtrackParaList` 用 `+176 pfnCreateParaclient` **现造**客户端（唯一合法来源）、注册为来源证据（通道 `'C'`、`seq` 全局唯一、按 `(doc,通道,值)` 可核）、**跨调用复用**（本侧**从不**对子段客户端发 `+192`）。⇒ 「**托管产出 ∧ 持有期内有效**」成立；「**解析到同一对象**」的**充分判据在托管侧** ⇒ 本侧只给出**必要**核对（见 §3）。**无自造/复用未认领句柄**。
3. ✅ **本趟增量（观测量，零行为改动）**：`FsQuerySubtrackParaList` 加 ① `[FSQSPL-CONSUME]` 消费者观测行（判据 `P1-paralist-wire-criteria.md §2.4` 同形；`id=` 取**只读**来源证据核对 `wpf_pts_prov_lookup`，**不**动 `wpf_pts_prov_claim` 的任何计数口）＋ ② **「拆接线」反腿闸** `WPF_PTS_QSPL_PROV`（缺省**开**；显式 `=0` ⇒ 具名 `reason=prov-bridge-unwired(reverse-leg)`、出参一字不写）。
4. ✅ **正/反腿成对现取（同一 `.so 2197fd72497619fb`／同装置 `:231`／同批工具，只差一个 env）**：**正腿**（缺省）`PTS_GUARD=PASS legs=2/2`／`PTS_COLORANCHOR=PASS k=24 hits=3`／`[FSQSPL-CONSUME]` `id=ok` **20,378/20,378**（`consume_bad=0`）；**反腿**（`WPF_PTS_QSPL_PROV=0`）⇒ `[FSQSPL] rc=-10000 reason=prov-bridge-unwired(reverse-leg)`×**1037**、`PTS_GUARD=FAIL`、`PTS_COLORANCHOR=FAIL hits=0`、两页帧回**空态集成员** `ef3fd6765f18f51b`（`colors 1220/636 → 383/383`）⇒ **该红必红：`subtrack-path` 的 `pfsparaclient` 来源是承重的**。
5. ✅ **零回归（症状门 ＋ 帧面成对）**：`.so 327dcce237e03e1f（改前）→ 2197fd72497619fb（改后）`；改前腿与改后（缺省）腿三帧**逐字节相同**（`AE=0`；`boot b21eb530afd3c66c`／`k23 10d0b9d54e649c10`／`k24 0bdb2dfd05952bc9`）、症状门逐格同（`alive=yes app_rc=143 magenta=0 colors 1220/636 ink=480000 failfast=0 ns=…FlowDocumentDemo｜…RichTextBoxDemo`）。
6. ✅ **门禁六件（现取）**：`nm -D --defined-only` ＝ `exports.txt` ＝ **718**（逐名 `diff` 零差异）；`PTSGAP=PASS tool=59 dead=11 artifact=1 ops=47 impl=47 so16=2197fd72497619fb exports=718`（rc=0）；`DEFREG=PASS declared=225 route_ids=225`；`REPORTID=PASS`；`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0`；`PTS_ENFE=PASS total=0`。
7. 🔴 **如实划界（本趟的核心判决）**：① `PRECOND-LS-PROVENANCE-BRIDGE` 的 `C2`（LS 会话标识）／`C4`（`cp↔dcp` 偏移）**本侧无源、不得自算** ⇒ **超 native 写域**，**未解除**；② `subtrack-path` 上 `R-4`（回收正确性）**无只读口** ⇒ `NOINFO` ＋ 具名 `PRECOND-NO-HANDLE-ACCOUNTING`；③ `resolve=wrong-object`（托管 `HandleToObject` 的解析结果）**本侧取不到**（无 P/Invoke／无导出口；且本侧从不对子段客户端发 `+192` ⇒ 无"回收后解析"观测面）⇒ 该格**不冒充**。

---

## §1 两条前置：判据原文 ＋ 逐条现取状态

> 纪律（照在册四要件）：**授权出处 ＋ 射程 ＋ 粒度 ＋ 逐入口状态**。判据**逐字**引自已登载的判据件（带件:行）；本席对**行号**只保证本次有效（内容锚一并给）。

### 1.1 `PRECOND-LS-PROVENANCE-BRIDGE`（**未解除**）

**判据原文（逐字，件:行）**：
- **立名** `build/MilBridge/P1-ls-provenance-contract.md:11`「它立 **`PRECOND-LS-PROVENANCE-BRIDGE`** 并给出 C1–C4 四列」。
- **来源件立名** `build/MilBridge/P1-ls-provenance-recon.md:99`「`plsrun`/`lscp` ↔ `nmp`/`dcp` 的**运行期对应关系与责任方**在仓内**不存在**，须由"内容层那一波"**新立**；且**本侧不能作为作者**，只能**保管并复算**」。
- **收口判词** `P1-ls-provenance-contract.md:60`「5 件共现里**没有任何一件**把 LS 侧的量与 PTS 的 `dcp`／`nmp` 连起来……**桥仍缺**」。
- **契约责任方表** `P1-ls-provenance-contract.md:67-72`（C1–C4）＋ **两条必红反腿** `:76-83`（偏移错一 ±1／跨段复用同一 `plsrun` 表）。

**逐条现取状态**：

| 锚点 | 内容 | 责任方（件:行） | 现取状态 |
|---|---|---|---|
| **C1** | `nmp`（段落名） | **宿主**；调用点 `+136 GetFirstPara` out（`PtsHost.GetFirstPara → ISegment.GetFirstPara(out fSuccessful, out nmp)`）；契约 `:69` | ✅ **有源**（本侧在回调内收下并保管 `drive_nmp`）；本侧**可校值**、**不可校语义身份**（`NOINFO-NMP-SEMANTIC-IDENTITY`） |
| **C2** | LS 会话标识（`plsrun` 起点 或 `LoCreateContext` 的 `ploc`） | **宿主 + LS**；契约 `:70`「❌ **不存在于我们的链上**……**须新立**」 | ❌ **不存在**（本侧既非作者也不在该会话内）⇒ 只能**接收并保管**；**未解除** |
| **C3** | `lscp ↔ cp`（**两参数对** `_cpFirst` ＋ `_lscpFirstValue`） | **托管**（`TextStore`，构造时一次性绑定）；两构造点 `FullTextState.cs:72-77`（主 store＝`0`）／`:87-102`（marker store＝`LscpFirstMarker=-0x7FFFFFFF`，`TextStore.cs:2376`）；契约 `:71` | ✅ **托管侧已有**（构造时绑定、之后只读）；本侧**能复算校验**（口径修正见契约 §2.2：**不得**把 `0` 当常量） |
| **C4** | `cp ↔ dcp` 偏移 | **宿主**；契约 `:72`「❌ **不存在**：全仓无填点 ⇒ **须新立**」；本侧「⚠️ **只能"复算校验"，不能自算**」 | ❌ **不存在** ⇒ **未解除** |
| **反腿 (a)/(b)** | 偏移错一 ±1／跨段复用同一 `plsrun` 表 | 契约 `:80-81` | ❌ **今天都不可跑**（无 LS 会话、本侧无 `dcp` 值）；契约写死「**不得**因"无读数"判绿或判红」 |

⇒ **判词**：**未解除**。C1/C3 在册，**C2/C4 在 native 写域内结构性不存在**（须"内容层那一波"先有 LS 会话 ＋ 文本段落进链）。本侧**不得**自算 `dcp`/`plsrun`（越级）。

### 1.2 `PRECOND-PARADESC-SOURCE-MISSING`（`scope=subtrack-path`；**未解除**，见 §2 的分项）

**判据原文（逐字，件:行）**：
- **入册** `build/MilBridge/P1-host-consume-route-criteria.md:183`（＝ `P1-lm-consume-witness-criteria.md:153` 逐字同）：「**段落描述数组 `arrayParaDesc` 无源**：唯一填写者 `PTS.FsQuerySubtrackParaList` native 未实现；射程＝`PtsHelper.cs:174-180` 那条 `rcPara.dv` 计算；粒度＝单次 `ArrangeParaList` 调用」。
- **加射程** `P1-host-consume-route-criteria.md:238`（＝ `P1-lm-consume-witness-criteria.md:208`）：dated 补记 · **`scope=subtrack-path`**。
- **分路径裁决** `P1-lm-consume3-verify.md:5`：「`PRECOND-PARADESC-SOURCE-MISSING` **应收窄为 `scope=subtrack-path(ContainerParaClient.cs:70→:72)`**，**不覆盖 `track-path(PtsHelper.cs:134→:137)`**」。
- **钥匙 vs 其后**（`build/MilBridge/P1-tail2-t0307-recon.md §2.2`）：`ContainerParaClient.cs:47/:271 FsQuerySubtrackDetails` 是**钥匙**（其 body 里 `Assert` 之后第一个实招、以 `cParas` 门控 `:70`/`:283`）；靶心 `FsQuerySubtrackParaList` 是**其后**。

**逐条现取状态**：

| 分项 | 内容（件:行） | 现取状态 |
|---|---|---|
| **数组来源** | `arrayParaDesc` 由谁填（唯一填写者 `PTS.FsQuerySubtrackParaList`；`PtsHelper.cs:633`） | ✅ **已闭**（前增量 `T-A12` 落地 `FsQuerySubtrackParaList`；本趟现取 `[FSQSPL] rc=0 … cParas=3 made=3 (ok=18368/18368)`） |
| **`:177` 承重几何** | `rcPara.dv = arrayParaDesc[index].dvrUsed - dvrTopSpace`（`PtsHelper.cs:177`；射程＝该计算） | ❌ **仍无源**：`subtrack-path` 的 `dvrUsed`／`dvrTopSpace`／`bbox` 本侧**无几何源** ⇒ 逐条保留 `memset` 后的 `0` ＋ 具名 `NOINFO-SUBTRACK-PARA-GEOMETRY`（现取 `[FSQSPL]` 行尾该 token）；⇒ **第 4 条（宿主消费 `rcPara.dv>0`）在 `subtrack-path` 上仍不可判** |
| **粒度假冒风险** | `t198` 警告：描述符值**恒为模型常量**（`seg_h=16`／`top_sp=0`）⇒ **别把"算术成立"读成"内容被消费"** | ✅ 遵（本趟**不**用几何做任何"填充成功"证据） |

⇒ **判词**：**分项判定** —— **数组来源已闭**、**承重几何仍无源** ⇒ 该前置**整体仍 `PARTIAL`**（**不写"已解除"**）。

---

## §2 判据（`t158` 七条合取 ＋ `resolve=wrong-object` 一票红 ＋ 两腿窗实验 ＋ R-1~R-4）：逐条现取

> **判据原文（逐字，件:行）**：
> - **七条合取** `build/MilBridge/P1-paralist-wire-criteria.md:127-136`（＝ `build/MilBridge/P1-ptsname-result.md:441` 的裁定四十五 (a)④）：「1. `rc=0`；2. `n>=1` 且 `n==cParas`；3. `src=managed-176`；4. 消费者行 `resolve=ok` 且 `h0` 与**同一 run** 的 `+176` 产出**同值**；5. `resolve=wrong-object`／`resolve=failfast`／`rc=-100002`／`rc=-10000` **各 0 次**；6. **≥2 个独立样本**判定一致；7. 每条读数带齐三格 ＋ 门状态」。
> - **`resolve=wrong-object` 一票红（机制）** `P1-paralist-wire-criteria.md:75`：「`resolve=wrong-object` 出现**任一次** ⇒ 本条判红（P4）」；机制见 `:81-86`（`IsHandle()=Obj!=null∧Index==0`；`ReleaseHandle` 把索引压回自由链、`CreateHandle` 复用之 ⇒ 已释放**已被复用**时 `HandleToObject` **静默返回另一个对象**、`as BaseParaClient` **还成功**）。
> - **两腿窗实验** `P1-paralist-wire-criteria.md:92-97`：W-1 窗内／W-2 窗外**各一腿**；**单腿只能 `NOINFO`**；「**不许**用 `[DRIVE-PROBE-SKIP] reason=gate-off` 的**缺席**当『窗外腿已跑』」。
> - **R-1~R-4 回收判据** `P1-paralist-wire-criteria.md:105-109`（＝ 裁定四十五 `P1-ptsname-result.md:440`）：**R-1 单次性**（二次 `+192` ⇒ `ReleaseHandle:211` `Assert` ⇒ **`FailFast` 不可捕获**）／**R-2 不晚于上下文销毁**（`:209` `Assert`）／**R-3 与那一次 `+176` 绑定**／**R-4 回收正确性不可由 native 单侧证明 ⇒ `NOINFO` ＋ 具名 `PRECOND-NO-HANDLE-ACCOUNTING`**；「🔴 **严禁用 `rc=0` 冒充"回收正确"**」。

**逐条现取（`subtrack-path`；本趟现取腿 `after-pos`；`WPF_PTS_QSPL_PROV` 缺省）**：

| # | 判据 | `track-path`（在册 `t160`） | **`subtrack-path`（本趟现取）** |
|---|---|---|---|
| 1 | `rc=0` | ✅ | ✅ `[FSQSPL] rc=0 reason=ok`（`ok=18368/18368`，`gap=0`） |
| 2 | `n>=1 ∧ n==cParas` | ✅ | ✅ 现取 `[FSQSPL] … cParas=3 made=3`／`cParas=1 made=1`；`cParaDesc` **只在真填完后**置（`*cParaDesc = cParas`，源见 `win32_pts.c` 该入口末段） |
| 3 | `src=managed-176` | ✅ | ✅ `[FSQSPL] src=SUBENUM(+136/+144)+managed-176`；`[FSQSPL-CONSUME] h=… src=managed-176`（**同一标记**） |
| 4 | 消费者 `resolve=ok` ∧ `h0` 与同 run `+176` 同值 | ✅（`+192` 代理） | ⚠️ **必要面成立、充分面 `NOINFO`**：`[FSQSPL-CONSUME] id=ok` **20,378/20,378**（`id=`＝**只读**来源证据核对：交出去的值**仍是**本 run `+176` 为**同一序号**产出的那个值，`prov_ord=i`、`gen_age=0`）；**托管侧解析**本侧**测不到** ⇒ `resolve=NOINFO(managed-side-no-pinvoke)` |
| 5 | `wrong-object`／`failfast`／`-100002`／`-10000` 各 0 | ✅ | ✅ 缺省腿 `[HC-UNHANDLED]=0`、`entry point named=0`、`[FSQSPL] rc=-10000` **0**、`failfast=0`、`id=ord-mismatch`／`id=no-evidence` **各 0**；⚠️ `resolve=wrong-object` **本侧无观测面**（见 §5-③） |
| 6 | ≥2 独立样本一致 | ✅ | ✅ 本趟一腿内两条腿（k24/k23）＋ 与改前腿逐帧相同（见 §5） |
| 7 | 每条带三格 ＋ 门状态 | ✅ | ✅ 见 §5（门：`WPF_PTS_QSPL_PROV` 缺省 `1`；腿内 `[FSQSPL]` 逐条带 `calls/ok/gap/consume_ok/consume_bad`） |
| — | **R-1**（`+192` 单次性） | ✅（延迟回收 +192 每代一次） | ⚠️ **对本入口不适用**：本侧**从不**对子段客户端发 `+192`（跨调用复用）⇒ 无该观测面 |
| — | **R-2**（不晚于上下文销毁） | ✅ | ⚠️ 不进该面（同 R-1）；**本侧自有子段对象**的递归回收由既有 `[SUBTREE-SELFTEST] bit3 destroy_recursive=1` 承担 |
| — | **R-3**（与那次 `+176` 绑定） | ✅ | ✅ 每客户端由**本 run `+176` 现造**（`child_clients[i]`／`child_clients_made` 记账），来源证据 `ev_seq` 全局唯一；**不换手** |
| — | **R-4**（回收正确性） | `NOINFO` ＋ `PRECOND-NO-HANDLE-ACCOUNTING` | `NOINFO` ＋ **同前置**（**本侧从不回收子段客户端** ⇒ 该面比 track-path **更弱**；**不拿 `rc=0` 冒充**） |

**⇒ 判词**：**`subtrack-path` 上七条合取「必要条件」全中，但第 4 条的充分面（托管侧解析）在 native 写域内取不到 ⇒ 保持 `PARTIAL`**；第 5 条的 `wrong-object` 一票红**本侧无观测面**（$注：本侧无 P/Invoke，测不到托管 `HandleToObject`；且本侧从不 `+192` 回收子段客户端 ⇒ 无"回收后解析"路径）。⇒ **不作"已绿"读**。

---

## §3 `subtrack-path` 的 `pfsparaclient` 来源：接线状态（现取复核）＋ 本趟增量

### 3.1 接线状态（**前增量落地**，本趟现取复核）

`win32_pts.c` 的 `FsQuerySubtrackParaList` 现取（件:行 ＝ 同件该入口体内）：
- **客户端由托管回调现造**：`for (i = child_clients_made; i < cParas; i++)` ⇒ 调 `+176 pfnCreateParaclient(dp->p_fsclient, obj->children[i], &h)`；`rc!=0 ∨ h==NULL` ⇒ **拒**（`reason=create-paraclient-failed`）。
- **注册来源证据**：`wpf_pts_prov_register(dp, h, 'C', "+176.CreateParaclient@FsQuerySubtrackParaList", i, dp->prov_gen)`（通道 `'C'`、`seq` 全局唯一、按 `(doc,通道,值)` 可核；见 `wpf_pts_prov` 定义与 `:1946-2057`）。
- **交出去**：`rg[i].pfsparaclient = obj->child_clients[i]`；`rg[i].pfspara = wpf_pts_sub_handle(obj->child_objs[i])`（本侧自有子段对象）；`rg[i].nmp = obj->children[i]`。
- **跨调用复用 / 不自回收**：`child_clients[]` 一经造出即复用；**本侧从不**对它发 `+192` ⇒ 与判据 `§2.1`「持有期＝托管对象生存期」**同形**。

⇒ 「**托管产出（`+176`）∧ 持有期内有效（对象生存期内）**」**成立**；「**无自造/复用未认领句柄**」**成立**（每个交出去的值都有 `'C'` 来源证据；数值等值**只作必要条件**，身份证据见 `N1` 台账）。

### 3.2 本趟增量（**观测量；零行为改动**）

`win32_pts.c` 的 `FsQuerySubtrackParaList`（**新增，同趟**）：
1. **只读来源证据核对** `wpf_pts_prov_lookup(p, doc, channel)`：匹配 `(doc, 通道 'C', 值)`，**真命中恰一条**才返该证据。**不记账、不拒**（认领谓词仍由 `wpf_pts_prov_claim` 独占 ⇒ **不动任何既有计数口**）。⚠️ **不看会话号**（本核对只回答"值是否仍是本 doc 上 `+176` 为**同一序号**产出的那个值"；会话号那一维由认领谓词管）。
2. **消费者观测行**（逐条，`cParas` 条）：
   ```
   [FSQSPL-CONSUME] i=<i> h=<hex> src=managed-176 id=ok|ord-mismatch|no-evidence prov_ord=<n> ev_seq=<n> gen_age=<n> resolve=NOINFO(managed-side-no-pinvoke) type=unknown(native-cannot-read) via=PtsHelper.ParaListFromSubtrack consume_ok=<n> consume_bad=<m>
   ```
   并新增 3 只读计数（`g_pts_fsqspl_consume_ok`／`_bad`／`_unwired`），在 `[FSQSPL]` 行尾以 `consume_ok=`/`consume_bad=` 引出。
3. **「拆接线」反腿闸** `WPF_PTS_QSPL_PROV`（缺省 **开**；仅显式 `=0` 才关）：闸关 ⇒ 本入口**不再把托管 `+176` 产出的客户端交出去**（逐字回"拒填"形态）：`reason=prov-bridge-unwired(reverse-leg)`、`g_pts_fsqspl_unwired++`、`out=UNWRITTEN`。

**为何不是"大改"**：`subtrack-path` 的**接线**在前增量已完成；本趟的诚实增量＝**把 `t158` 的消费者判据同形引到这条路上**，并给出**可成对的极性**（否则"该来源是否承重"在册无名）。**导出面一字未动**（无新增/删除任何导出）。

---

## §4 成对读数（**同装置 `:231`**；证据 `~/tA63-work/legs/`）

### 4.1 三趟腿（**只差权威 `.so` 或一个 env**，其余全同）

| 腿 | 权威 `.so` | env | 证据目录 | `LEGS_RUNNER` |
|---|---|---|---|---|
| `before` | `327dcce237e03e1f`（改前） | （无） | `~/tA63-work/legs/before/` | `PASS requested=2 obtained=2 refused=0` |
| `after-pos` | `2197fd72497619fb`（改后） | （无） | `~/tA63-work/legs/after-pos/` | `PASS requested=2 obtained=2 refused=0` |
| `after-neg` | `2197fd72497619fb`（改后） | `WPF_PTS_QSPL_PROV=0` | `~/tA63-work/legs/after-neg/` | `PASS requested=2 obtained=2 refused=0` |

### 4.2 症状门（逐腿现取，`leg_*.env`）

| 量 | `before` | `after-pos`（缺省） | `after-neg`（拆接线） |
|---|---|---|---|
| `k24` | `alive=yes app_rc=143 magenta=0 colors=1220 ae=220019 ink=480000` | **同** | `alive=yes app_rc=143 magenta=0 colors=383 ae=15386` |
| `k23` | `alive=yes app_rc=143 magenta=0 colors=636 ae=136292 ink=480000` | **同** | `colors=383 ae=0` |
| `[HC-UNHANDLED]` | `0` | `0` | **1036** |
| `entry point named` | `0` | `0` | `0` |
| `failfast`（`FAILLINE`） | `0`／`unrec=0` | `0`／`unrec=0` | `0`／`unrec=0` |
| `PTS_GUARD` | `PASS legs=2/2` | **`PASS legs=2/2`** | **`FAIL`**（`n1-frame-unestablished` ＋ `color-anchor-absent`） |
| `PTS_COLORANCHOR`（k24） | `PASS hits=3`（`GhostWhite=9794 Beige=910 DarkGreen=44 LightGoldenrodYellow=5830`） | **`PASS hits=3`（同值）** | **`FAIL hits=0`** |
| `PTS_ENFE` | `PASS total=0` | `PASS total=0` | `PASS total=0` |

### 4.3 帧面（本席自算，只读 PNG；`AE`＝逐像素差计数）

| 对 | `boot` | `k23` | `k24` | `last` |
|---|---|---|---|---|
| `AE(before, after-pos)` | **0** | **0** | **0** | **0** |
| `AE(before, after-neg)` | 0 | 186275（内容区 174476） | 210578（内容区 204628） | 186275（内容区 174476） |
| `fr_sha(before)` | `b21eb530afd3c66c` | `10d0b9d54e649c10` | `0bdb2dfd05952bc9` | `10d0b9d54e649c10` |
| `fr_sha(after-pos)` | `b21eb530afd3c66c` | `10d0b9d54e649c10` | `0bdb2dfd05952bc9` | `10d0b9d54e649c10` |
| `fr_sha(after-neg)` | `b21eb530afd3c66c` | `ef3fd6765f18f51b` | `ef3fd6765f18f51b` | `ef3fd6765f18f51b` |

⇒ **零回归**（`before` ≡ `after-pos`，逐字节）；**反腿该红必红**（两页帧落**在册空态集** `FRAME_EMPTY_SET` 成员 `ef3fd6765f18f51b`）。

### 4.4 本趟增量的现取读数

| 量 | `before`（`327dcce237e03e1f`） | `after-pos`（`2197fd72497619fb`） | `after-neg`（`=0`） |
|---|---|---|---|
| `[FSQSPL] rc=0` | 18148 | 18368 | **0** |
| `[FSQSPL] rc=-10000 reason=prov-bridge-unwired(reverse-leg)` | 0 | 0 | **1037** |
| `[FSQSPL-CONSUME]`（`id=ok`） | 0（**旧件无此观测行**） | **20378（全 `id=ok`）** | 0 |
| `id=ord-mismatch` ／ `id=no-evidence` | — | **0 ／ 0** | — |
| 示例成功行 | — | `[FSQSPL] rc=0 reason=ok entry=FsQuerySubtrackParaList ctx=0x619ede856b30 psub=0x619ee34b3ef4 cParas=3 made=3 cli_total=3 src=SUBENUM(+136/+144)+managed-176 calls=1 ok=1 gap=0 consume_ok=3 consume_bad=0 NOINFO=subtrack-para-geometry(dvrUsed/dvrTopSpace/bbox=0)` | — |
| 示例反腿行 | — | — | `[FSQSPL] rc=-10000 reason=prov-bridge-unwired(reverse-leg) entry=FsQuerySubtrackParaList ctx=0x633e1edfbc60 psub=0x633e1ec7c104 cParas=3 calls=1 ok=0 gap=1 out=UNWRITTEN` |

> ⚠️ **如实记**：`before`(18148) 与 `after-pos`(18368) 的 `[FSQSPL] rc=0` 条数**不同**。本改动**不改控制流**（观测行 ＋ 缺省开闸），且三帧**逐字节相同**、症状门逐格同 ⇒ 判为**趟间波动**（应用排版遍数随运行而变），**非本改动引起**；**不**把它读成"能力前进"。

### 4.5 回收／身份自检（现取，三腿同 `mask=0x1f`，即 5/5）

- `[PROV-SELFTEST] mask=0x1f`（`claim_ok/wrong_object/aba/stale/zero_evidence` 各 1）⇒ **来源证据谓词**的**三条反极性（`wrong-object`／`ABA`／`stale-gen`）该红必红**。
- `[SUBTREE-SELFTEST] mask=0x1f`（`child_claimable/stub_handle_rejected/missing_child_rejected/destroy_recursive/live_restored` 各 1）⇒ **销毁递归 ⇒ 句柄**不再可认领**（**本侧自有对象的回收判据**）。
- `[HCOUNTLEDGER] pair=distinct live_A_after=3 live_B_after=0 distinct=1 v=PAIR-DISTINCT-AND-SELF-CONSISTENT`（**独立于 `rc`** 的台账读数，照 `t158` R-4 禁引用句在位）。

---

## §5 门禁六件（现取；`rc` 一律取自 `>out 2>err; echo $?` 形态）

| 门 | 读数 | rc |
|---|---|---|
| `nm==exports` | `nm -D --defined-only` ＝ **718** ＝ `exports.txt` 行数；**逐名 `diff` 零差异** | 0 |
| `PTSGAP` | `PASS tool=59 dead=11 artifact=1 ops=47 impl=47 so16=2197fd72497619fb exports=718`（`DRIFT` 已消：DECL 的 `so16` 跟权威件换） | 0 |
| `DEFREG` | `PASS declared=225 route_ids=225`；`DECLDRIFT=0 keys=-` | 0 |
| `REPORTID` | `PASS files=340 ids=2247 declared=225`（本件落盘前 `339` ⇒ 落盘后 `340`，`+1` 即本件） | 0 |
| `HANDOFF_MV` | `PASS cells=9 equal=8 manual=1 mismatch=0`（`inputs_fp` 因写域件在覆盖面内 ⇒ 位移 `a5984a2c…`→`c62c9f8a…`，已按第 `28` 条契约在 `HANDOFF-NEXT.md` 文件尾**只增**追写） | 0 |
| `PTS_ENFE` | `PASS total=0 by_name=none`（两腿） | 0 |

---

## §6 逐件 `sha16`（现取）

| 件 | 改前 | 改后 |
|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `2b8142ced5b68b76`（670589 B） | **`c80a03e9633641a7`**（674995 B） |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so`（**非仓内件**） | `327dcce237e03e1f`（490072 B） | **`2197fd72497619fb`**（490248 B） |
| `src/WpfGfx.Linux.Native/bin/exports.txt`（**非仓内件**） | `20b6d9aa3125bbc4`（718 行） | **未变**（`20b6d9aa3125bbc4`／718 行 ⇒ 导出面零变化） |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `5965cc3e9ed89498` | **`12778c62c4dc153f`** |
| `docs/ROUTES.md` | `e67ebf7f8e6e3913` | **`9ba07aec3cc39910`**（`TASK-0307` 行加一条 dated 结账） |
| `build/MilBridge/HANDOFF-NEXT.md` | `d03e4c2b7a3dc6e1` | **`4c415997bf972e7b`** |
| `docs/WAVE66-PREREGISTRATION.md`（**冻证据**） | `bf6b683d94549087` | **未变** |
| `build/PresentationFramework.Linux/reapply-patches.py`（生成器） | — | **未变（零托管改动）** |

---

## §7 诚实边界（**防读宽**，逐条）

1. 🔴 **本趟**不是**「把桥接上了」**：`subtrack-path` 的接线是**前增量**（`T-A12`／`T-A25`／`T-A37`）落地的；本趟是**现取复核 ＋ 判据同形 ＋ 极性**。凡"桥已接"读法**只准**读到「native 把**由托管 `+176` 产出、持有期内有效**的客户端句柄交给列表消费者」这一件事。
2. 🔴 **`resolve=ok` 本侧给不出**：`[FSQSPL-CONSUME] id=ok` 只主张「交出去的值**仍是**本 run `+176` 为**同一序号**产出的那个值」（**必要非充分**，且**不看会话号**）；**托管 `HandleToObject` 的解析结果**本侧**无观测面**（无 P/Invoke／无导出口）⇒ `resolve=` 写 **`NOINFO(managed-side-no-pinvoke)`**。**严禁**把 `id=ok` 读成 `resolve=ok`。
3. 🔴 **`resolve=wrong-object` 在 `subtrack-path` 上取不到**：`track-path` 用「延迟回收上一代 + `+192` rc」做代理观测面；`subtrack-path` 的客户端**本侧从不回收**（跨调用复用）⇒ **无"回收后解析"路径** ⇒ 该一票红**本侧无法构造**。⇒ 该格 `NOINFO`，**不冒充**。
4. 🔴 **两条前置仍 `PARTIAL`**：`PRECOND-LS-PROVENANCE-BRIDGE` 的 **C2/C4** 本侧**结构性不存在、不得自算**（越级）⇒ 须"内容层那一波"；`PRECOND-PARADESC-SOURCE-MISSING` 的**承重几何**（`dvrUsed`/`dvrTopSpace`）在 `subtrack-path` 上**仍无源** ⇒ 第 4 条（宿主消费 `rcPara.dv>0`）**不可判**（**不得**用零值或模型常量冒充）。
5. 🔴 **R-4 不许用 `rc=0` 冒充"回收正确"**：`subtrack-path` 上**连"回收"都不发生**（本侧不回收子段客户端）⇒ 该面比 `track-path` **更弱**；`PRECOND-NO-HANDLE-ACCOUNTING` 仍成立（`[HCOUNTLEDGER]` 只覆盖 **native 自有台账**，不含托管 `_unmanagedHandles` 自由链）。
6. 🔴 **`[FSQSPL] rc=0` 条数趟间不同（18148 vs 18368）**：**非**能力前进（帧逐字节同、症状门逐格同）；本改动不改控制流。
7. **`bin/*` 非仓内件**：`src/WpfGfx.Linux.Native/bin/` 在 `.gitignore` ⇒ 由 `build-shim.sh --symbols` 每次重产；`nm==exports` 是**构建不变量**。
8. **未跑整趟 `verify-all`**（照派单）；本节所有"不得读成绿"的口径照在册红榜 `P1–P10`。

---

## §8 遗留（下一增量具名靶）

- **`PRECOND-LS-PROVENANCE-BRIDGE`（C2／C4）**：须"内容层那一波"（先有 LS 会话 ＋ 文本段落进链）；native **不得**自算 `dcp`/`plsrun` ⇒ **本写域内不可解除**。
- **`subtrack-path` 的承重几何（`:177` 两操作数）**：本侧无几何源；唯一诚实来源＝托管布局（**越 native 写域**）。若将来由宿主给出，本侧**只能复算校验、不得自算**。
- **`resolve=wrong-object` 观测面**：若要覆盖 `subtrack-path`，须**先有一条合法回收路径**（`+192` 在持有期外的触发）；本趟**无**（不冒充）。
- **`PRECOND-HOST-CONSUME-OBSERVATORY-OUT-OF-DOMAIN`**（在册）：托管侧消费者观测不在本件写域 ⇒ 「解析到同一对象」的**最终判据**仍须托管侧读数。

---

`P1-TAIL2-LSPROV 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 880c59f72e7bb8e4（末行＝本行）`

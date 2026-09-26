# `P0-w77-repair-report.md` —— `t17`：波 `#77` 的**修复记账**（车道 `waveman`）

> 触发：`t6` 独立复验（`build/MilBridge/V77-verify-report.md`）判 **`failed`** —— 主链读数全过，但**两条验收 FAIL ＋ 七句现场被推翻/打折扣**。
> 本件逐条关账 **F1–F7** ＋ 主控中途追加的**仓外可执行默认值**一族。**本波不冻结**（repair 任务）；`~/w21-verify/**` 一字节未动（主控写域）。
> 判据/驱动器：`~/w186a/w77rep/`（`bin/`／`logs/`／`backup/`）。

## §F1（真回归，必修）—— 5 件 `dirname` 层数少一层

**现象**：`#77` 的 21 件重指向里 5 件的派生式解析到 **`<仓>/build`**（而非仓根），其**第一个消费点拼出的路径不存在**；用改前旧值拼则存在 ⇒ **真回归**。

| 件 | 行 | 层数 | before | after |
|---|---|---|---|---|
| `build/DirectWrite.Linux/wic-shim/frames-gen.py` | 33 | 3→4 | `0b114c92b0d24a59` | `87d8cd0dfcf3a665` |
| `build/MilBridge/tools/analyze-layout-b34.py` | 12 | 3→4 | `010fd091effc89d9` | `c783ff683ebaea2e` |
| `build/MilBridge/tools/extract-layout-b34.py` | 13 | 3→4 | `ea66f3f260b90cdc` | `59b563eb57b62cee` |
| `build/MilBridge/tools/t1c-inputtrace-verify.py` | 32 | 3→4 | `0d3542bb0233f261` | `5cec72436bfb0ac8` |
| `build/MilBridge/tests/W81AWindowProbe/w81a-a0-analyze.py` | 28 | 4→5 | `86923276bf646553` | `317da8dc21cedf5e` |

**证明 = 真跑（不是看源码）**：把 **22 条替换表达式**逐条在**真实自指路径**下求值（`.py` 注入 `__file__`；`.sh` 注入 `${BASH_SOURCE[0]}` 后交 `bash`），断言「解析结果 == 仓根物理路径」；5 个声明了**消费点**的件再加断言「结果 ＋ 后缀**存在**」。
```
BEFORE  REPOINT_ROSTER exprs=22 ok=17 bad=5 consume=5 consume_ok=5   rc=1   （~/w186a/w77rep/logs/f1-before.txt）
AFTER   REPOINT_ROSTER exprs=22 ok=22 bad=0 consume=5 consume_ok=5   rc=0   （~/w186a/w77rep/logs/f1-after.txt）
```
复算命令：`python3 ~/w186a/w77rep/bin/repoint_roster_eval.py`。

## §F1-射程缺口 —— 二选一里选「纳入门禁」，并把它做成**真牙**

这 5 件原**既不在 `verify-all` 接线、也不在 `fp_inputs()` 覆盖面** ⇒ 门禁看不见。
**处置**：新件 `build/MilBridge/tools/wave-freeze-consistency-check.py` 的 **档① `WFREEZE_ROOTDEFAULT`**（roster 22 条，逐条真跑）＋ 接进 `build/close-wave.sh` 的 **`[5c/6]`**（冻前；`FAIL` ⇒ `run()` 当场 `exit` ⇒ 汇总与两哨兵都不落）＋ **纳入 `fp_inputs()` 覆盖面（211 → 212）**，`verify-all.sh` 的 `[42] --expect` **同趟**按现取改成 **212**（现取 `infp.sh list|wc -l` = 212；**不许分段累加**）。
**代价（如实）**：① 覆盖面 ＋1 ⇒ `inputs_fp` 位移（见 §账目）；② 本牙**只覆盖 roster 的 22 条** —— 新出现的"自指派生式"**不在射程**，除非同时进 roster；**不许把本档读成"全仓派生式都被看住了"**。
自测：`WFREEZE_CONSISTENCY_SELFTEST=PASS cases=5 pass=5 fail=0`（S1 干净镜像 ⇒ 档① PASS／S2 少一层 ⇒ FAIL 并点名／S3 声明与 `GENS` 不符 ⇒ FAIL／S4 两条权威分叉 ⇒ FAIL／S5 一致 ⇒ PASS）。真树三档全绿：`WFREEZE_CONSISTENCY=PASS rootdefault=PASS decl=PASS nineauth=PASS`。

## §F2 —— 受版控**派生件**入笔（16 件；根因不是 churn）

现取 `porcelain` 曾为 15→16 件。**根因**：这些件**HEAD 内容里带的是旧路径**（最后提交 9/20、9/22、P0），整波重建把它们写成新路径 ⇒ **每跑一次整波必脏**。
**本波按径 `git add` 入笔、逐件点名（不是 `git restore` 丢件）**：`build/PresentationCore.Linux/{SR.g.cs,ARTIFACT-SRC-FP.txt}`／`build/PresentationFramework.Linux/{SR.g.cs,ARTIFACT-SRC-FP.txt}`／`build/ReachFramework.Linux/SR.g.cs`／`build/System.Windows.Input.Manipulations.Linux/SR.g.cs`／`build/System.Xaml.Linux/SR.g.cs`／`build/UIAutomationProvider.Linux/SR.g.cs`／`build/UIAutomationTypes.Linux/SR.g.cs`／`build/WindowsBase.Linux/{SR.g.cs,ARTIFACT-SRC-FP.txt,PORT-CHANGES.md}`／`build/.applocal-selftest.log`／`build/wave-audit.log`／`tests/parity/linux/parity-results.json`（15 件）＋ `build/MilBridge/V77-verify-report.md`（`t6` 的复验报告，本修复的依据件）。
**声明**：全部为**构建/日志派生物、非逻辑变更**。
**待办（长期归属，主控定）**：tracked 派生件要么进 `.gitignore` ＋ `git rm --cached`，要么在生成器里**去掉绝对路径**（它们现在是"路径承载体" ⇒ 跨树/跨跑必变）。

## §F3/§F4/§F5/§F6 —— 四条更正与新登记

- **F3（`D-G149` 建议号）**：`#77` 冻结块的**九位行 `provider` 写成上一代值** `1f9511a7ef395bfe`，而同块位移行与**全部** `BASELINE tier=` 机读行写现值 ⇒ 同块两个授权来源矛盾。根因：记录模板把 `provider`／`wic_shim` 写成**字面量**，且冻结器 `_PREV_SRC`(7 键)／`_TIER_MAP`(5 位)**都不含 `provider`** ⇒ 三道核**全盲**（我用活件函数跑的 A2 臂：把 provider 写对/写误，结论**逐字不变**）。**不改冻结块**；dated 更正落 `docs/WAVE77-PREREGISTRATION.md §8.3`／`docs/ROUTES.md §15ae`／`build/MilBridge/HANDOFF-NEXT.md §4-追`；**给冻结器的补丁设计**（`provider`/`wic_shim` 进 `_PREV_SRC`／`_TIER_MAP`／`GENS`，＋"模板里不许写死九位值"的渲染前断言）写在预登记 §8.3。
  **口径句**：**"记录模板里任何九位值都不许写字面量：写死的值一旦被重建改变，块内两个授权来源就会互相矛盾，而三道核都看不见。"**
- **F4**：「两趟 post **唯一**原始差异是 `wall_s`」→ 更正为 **读数域差异 0；标签/环境类差异 24 行**（逐类：路径类／跑次戳与时间戳／环境余量 `avail_kb`·`mem_mb`／耗时 `wall_s`·`held`）。"判词行逐字相同"成立，错的只是**"唯一"这个量词**。
- **F5**：预登记 FROZEN ⑩/⑥（`allow_changed={'pf'}` ＋ `pf_required=True`）与 `GENS['#77']`（五格 ＋ `False`）不一致 ⇒ 已落**机读声明行** `WFREEZE-DECL:`（预登记 §7.7）＋ 牙 **档② `WFREEZE_DECL`**（读声明 ↔ 用 AST 只读抽 `GENS` 逐字段比）⇒ 现读 `WFREEZE_DECL=PASS gen=#77 allow_changed_decl=dwf,pc,pf,provider,windowsbase allow_changed_gens=dwf,pc,pf,provider,windowsbase pf_required_decl=False pf_required_gens=False`。
- **F6（`D-G150` 建议号）**：同名产物**两条都自称权威**的路径无牙钉住相等。**规约权威 = `build/DirectWrite.Linux/Provider/bin/<CFG>/DirectWrite.Linux.Provider.dll`**（三条依据：① 工程产出目录；② **冻结器 `NINE`** 用它；③ `applocal-expect.py`／`check-applocal-sync.sh` 的 `ITEMS` 用它）⇒ `build/PresentationCore.Linux/bin/<CFG>/…` 是**副本**。**处置**：副本刷成权威（`4041df9a704abfed` → `609192a419d125f2`；旧件留档 `~/w186a/w77rep/backup/f6/`）＋ 牙 **档③ `WFREEZE_NINEAUTH`**（provider 两条 ＋ `WindowsBase` Release/Debug 两条；分叉即 FAIL 并逐条点名两条路径与各自 sha16）。**口径句**：**"同名产物凡有多条自称权威的路径，必须有一条牙钉住它们相等；否则判据的输出永远取决于『谁最后重建了哪一条』。"**
- ⚠️ **随之发生的九位位移（如实）**：权威 `provider` 由 `4041df9a704abfed` 变为 `609192a419d125f2` ⇒ **在册九位的 `provider` 与现场不再相同**（冻结点之后的重建位移，非语义变化）。

## §F7 —— `TASK-0745` 的**语义返工设计与两极化证据**（只交设计与证据；**由主控落**）

驱动器 `~/w186a/w77rep/bin/f7_design.py`（`cp -a` 活件进沙箱、`ast` 逐字抽 `_BLK_HDR/_NINE_HDR/_PREV_SRC/_TIER_MAP/_block_of_prev/check_prev_values/GENS/NINE` 后 `exec`；**无一处重新实现判据**；语料 = 冻结器自己写出的**真 `#77` 块**）。读数 `~/w186a/w77rep/logs/f7.txt`。

**(3) 现行器为何 `bad=7`（逐条分解）**（`G = GENS['#77']`，`prev_*` ＝ **上一代值**；被搜文本 ＝ **本代 `#77` 块**）：
```
bad=7 checked=2 skipped=[]
MISMATCH key=prev_infp 表项=bb54413c8a3f0474a3d04e41dc08ec29fb993f7ea7a8ab689ae29f372904eb9a 基线块=b67560f2ff28932b69cf198aa68ed91ca66f582180d27d4af929deca54dd540c
MISMATCH key=prev_pc   表项=722e0ab8205b7c3f 基线块=53fd7fffcdb30243
MISMATCH key=prev_pf   表项=963c59991fd1f709 基线块=4fcd2ca021c39064
MISMATCH key=prev_wb   表项=2e4e46e539a72cd7 基线块=07c89f1872c1a3c1
TIER-DISAGREE key=prev_pc tier=53fd7fffcdb30243 表项=722e0ab8205b7c3f
TIER-DISAGREE key=prev_pf tier=4fcd2ca021c39064 表项=963c59991fd1f709
```
（`checked=2` = `prev_bsfp`／`prev_wsh` 两键**确实相同** ⇒ 通过。）⇒ **成因**：`prev_*` 按 `TASK-0730` 的既定语义是**上一代值**，而 `E1` 把**本代块**拿去与它们比 ⇒ **任何"有位移的世代"必被拒冻**（`#78` 就有五位位移）。

**(1) 正确期望语义 ＝ 「本代块 vs **本代值**」**（不是搜上一代块）。理由：`E1` 的动机（`D-G145`）是"本代记录带齐下一代所需的机读形态"⇒ 它要判的是**本代块里那几行写对没有**，比对基准只能是**本代值**（冻结那一刻从树上现取）。两极化（真跑）：
```
ARM1_CURRENT_SEMANTICS        bad=7   ← 被咬过的那一格（现行器会拒任何位移世代）
ARM2_SAME_BLOCK_NOW_TABLE     bad=0   ← 同一块、表项换本代值 ⇒ 现象消失（成因归于语义而非块）
ARM3_V2_DESIGN_ON_REAL_BLOCK  bad=2   ← v2（九位全部含 provider）在**真块**上抓出 2 条：provider（= `D-G149` 真缺陷）＋ `_nfp`（本修复把覆盖面 +1 后的冻结点后位移）
ARM3B_V2_ON_CORRECTED_BLOCK   bad=0   ← **写对的**本代块 ⇒ 绿（"有位移的真实世代必须 bad=[]"）
ARM4_V2_MISSING_FORM          bad=1   ← 机读形态缺失 ⇒ 必红（`HITS!=1 key=_nfp hits=0`）
ARM5_V2_DUP_FORM              bad=1   ← 形态出现两次 ⇒ 必红（`hits=2`）
F7_DESIGN=PASS arms=5
```
**(2) 九位全部纳入核的键表**（v2 的 `NINE_ALL`）：`bridge`／`pc`／`pf`／`windowsbase`／`provider`／`win32shim`／`wic_shim`／`hbtextline`／`dwf`（＋块内 `inputs_fp`、`BRIDGE_SRC_FP`）——即把 `provider`／`wic_shim`／`bridge`／`hbtextline` **补进**今天的 `_PREV_SRC`(7 键) 与 `_TIER_MAP`(5 位)。
**交付形态**：设计 ＋ 证据 ＋ 建议补丁骨架（`provider`/`wic_shim` 两键入表 ＋ 渲染前"模板不许写死九位值"断言）；**落地由主控**。
**如实划界**：`ARM3` 的 `_nfp` 一条是**本修复自身**造成的（覆盖面 211→212 ⇒ 冻结点后的现值位移），**不是 `#77` 的缺陷**；把它单列，不和 `provider` 混算。

## §主控追加 —— 仓外**可执行默认值**一族（与 F1 同族，合并记账）

`t7` 于 `22:12:07` 撤除旧路径符号链接 ⇒ 凡把旧路径写成**默认值**的可执行件都**读不到**（不是"读旧树"）。
**处置（只碰 `*.sh`／`*.py` 的**非注释行**；`*.md`／`*.log`／`*.tsv`／历史报告一律不动）**：
```
OUTSIDE_REPOINT EDIT=68 total=68 hits=69        （逐件 cp -p 备份 ＋ 写前 D-G126 断言 ＋ 逐件命中数断言）
LEFTOVER_NONCOMMENT=0
OUTSIDE_RESOLVE ok=14 bad=0                     （5 包入口 ＋ ~/ 根代表：真跑解析 == $N 物理路径）
```
- **5 个待命包入口（`#78` 用它）**：`w180a/w77/landing.sh:31`／`w181a/w7x/landing.sh:26`／`w181a/w7x/bin/{00-setup.sh:4,03-genimpact.sh:10,leg.sh:12,w181a-go.sh:14}`／`w182a/landing.sh:26`（`FORBIDDEN`）／`w183a/landing.sh:26`（`R_DEFAULT`）／`w183a/rehearse.sh:10`；`w180a/scratch-fork-0745/prep-probes.py:5`（全路径字面量，解析到 `$N/samples/…`，逐字核 OK）。**`w184a` 无**（其 9 处命中全是注释/报告）。
- **`~/` 根下**：`hc-*.sh`（11 件）＋ `run-hc.sh` ＋ 历史链驱动 `w29`–`w55`（44 件）等共 **56 件**已重指向；`~/heavy-slot.sh` 与 `~/mvp-accept.sh` **本就不含旧路径** ⇒ **零改动**（已逐件核）。
- **真跑**：`bash ~/w183a/rehearse.sh` ⇒ `REHEARSE=PASS e1_dry=0 e1_apply=0 e1_idempotent=0 e2_symlink=4 e2_authority=4 R_writes=0`（`rc=0`）。
- **未动（具名，非"可执行默认值"）**：`~/w*/**` 下的**旧镜像/沙箱/补丁档/历史跑次**（如 `w166a/w75/tree/*/build/MilBridge/tools/nl-intent-check.sh`、`w-janitor-quarantine-*/…`）—— 它们是**证据件**，改它等于篡改；`w164a/patches/{00-before,01-after}/…` 是**成对补丁的证据**；`census/shot-*.png` 属证据位。**逐类计数**：全量命中 1,299 处（`default` 761／非默认 537／注释 1），其中**本波重指向 69 处**，其余 **1,230 处**落在上述证据类（**不改**）。
- **`NOINFO`（不改并具名报告）**：`~/w40-backup-w27-freeze.py` 等引用 `~/w21-verify/` 的件——那是**主控写域**，本波不碰。

## §`infp.sh`（**归属更正：本笔属于 `t17`，不是主控**）

主控 `2026-09-26` 更正：`~/w153a/bin/infp.sh:18` 的"只加覆盖点 ＋ 重指向"是**本车道（`t17`）**做的（主控那一笔 `anchor hits=0` ⇒ **零写入**）。本报告按此记账：**before `19da2f6ca51b305b` → after `a6baa0ef73b01e61`**（`cp -p` 备份 `~/w186a/w77rep/backup/infp.sh` ＋ 写前 `D-G126` 断言）。
**两极化（本波补跑）**：
- **正极（默认档）**：`bash ~/w153a/bin/infp.sh fp` ⇒ `99db4fb592aba8f7dc53263d9914fa7c47c3f542207c35736ade1cddc08b6709`；`list|wc -l` ⇒ **212**。（⚠️ 主控引的 `b67560f2…`／`211` 是**加覆盖面之前**的读数；本波把新牙纳入覆盖面 **+1** ⇒ 现值如上，**逐条归因见 §F1-射程缺口**。）
- **反极（`INFP_R` 指到不存在的根）** ⇒ 必须复现"抽不出"：`INFP=NOINFO reason=extract-empty`（证明**默认档真被消费**）。
- **与替代件同值**：`bash ~/w-infp-at.sh $N fp` ⇒ 同值；`n` ⇒ 212。
- ⚠️ **更正主控第二条**：`~/w-infp-at.sh` **没有坏** —— 它把仓根作为**第 1 个参数**（`R="${1:?用法: w-infp-at.sh <repo-root> [fp|list]}"`），`bash ~/w-infp-at.sh fp` 是把 `fp` 当成了根参数 ⇒ 那是一次**用法错**，不是硬编码旧路径（`grep -c` 旧路径 = **0**）。⇒ **既不选 (甲) 也不选 (乙)**：它是**能用的**、且是**独立实现**（100 行 vs 26 行、`diff` 120 行 ⇒ 不是拷贝）⇒ 保留为**互核材料**。

## §账目同趟
- 覆盖面 **211 → 212**；`[42] --expect` 同趟 **212**；`inputs_fp` **`b67560f2ff28932b69cf198aa68ed91ca66f582180d27d4af929deca54dd540c` → `99db4fb592aba8f7dc53263d9914fa7c47c3f542207c35736ade1cddc08b6709`**，**逐条归因**：① 新增 `build/MilBridge/tools/wave-freeze-consistency-check.py` 入覆盖面（+1 件）；② 5 处 `dirname` 修复（`frames-gen.py`／`analyze-layout-b34.py`／`extract-layout-b34.py`／`t1c-inputtrace-verify.py`／`w81a-a0-analyze.py`，其中 4 件**在覆盖面内** ⇒ 内容变）；③ `build/close-wave.sh` 自身在覆盖面内且被改（+1 行 ＋ 接线）。
- 九位**新增位移**：`provider` 由 `4041df9a704abfed` → `609192a419d125f2`（§F6 的副本同步所致，非本波语义变化）。
- 冻结器 `~/w21-verify/w27-freeze.py` **本波一字节未动**（现读 `6bf3c5c77eee8dd8`，`grep -c check_record_forms` = **0**）。
- `DEFREG=PASS declared=182`；⚠️ 我登记的三个**建议号**（`D-G149`／`D-G150`／`D-G151`）**不在** `defect-registry-check.sh --emit` 的 ID 域里（现读 `declared=182` 未含它们）⇒ **配号与入册请主控裁**。

## §我推翻了哪句话（逐条）
1. **「两趟 post 唯一原始差异是 `wall_s`」**（`#77` 报告/记录）—— 实为 **24 行标签/环境类**（§F4）。
2. **「21 件旧路径重指向 ⇒ 默认值由仓根现推」** —— 文本域对（0 命中），**执行域 5 处不符**（§F1，真跑证实）。
3. **「`porcelain=0`」** —— `#77` 推送后现取 15→16 件（§F2）。
4. **「`TASK-0745` 补丁未落、冻结器一字节未动」** —— 冻结当时为真；随后主控把它落进活件，**现已回退**（现读 `6bf3c5c77eee8dd8`／`check_record_forms`=0）⇒ 该句**时点相关**，报告里按现读改写。
5. **主控两处归属/口径更正**（由其本人 `2026-09-26` 消息给出，本件照此记账）：① `infp.sh` 那一笔**属于 `t17`**、主控那笔 `hits=0` 零写入；② `~/w-infp-at.sh` **没坏**，是**用法错**（根是第 1 参数）。
6. **新推翻（本件自己）**：`D-G149`/`D-G150`/`D-G151` 三个建议号**进不了**注册器的 ID 域 ⇒ 之前的 `#77` 报告里"登记"这类散文号，**实际不改变 `declared=` 计数**（`DEFREG` 照旧 `PASS`）——**"登记"与"入册"是两件事**，本条已如实写进 §账目。

## §边界与 `NOINFO`
`TASK-0744` 的线上等长替换真腿仍**不可独立复跑**（仓内零装置）｜`~/w21-verify/**` 为主控写域（本波零写入）｜`cropus/census` 证据位不动｜`infp.sh` 的 `list` 口径与替代件**同值**但不构成"两套独立判据"（同一 `sed` 抽函数体 ＋ 同一双跳管线 ⇒ **同源**）｜Roster 的 22 条**不是**"全仓派生式全集"｜`~/w*/**` 的 1,230 处旧路径命中**属证据类，未动、也**不做**等价性证明。

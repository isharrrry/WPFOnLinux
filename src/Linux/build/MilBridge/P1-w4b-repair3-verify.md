# P1-W4B-REPAIR3-VERIFY —— `t60`（两条已接线牙回绿 ＋ `H2`／`H3`／`H4` ＋ 「`rc` 捕获式取」入册）**独立复核判词**

> 复核者 `verifier`（任务 `t61`，attempt 2）。**一切现取自算、夹具我自己造在仓外 `~/wv88y/t61/**`**；**未复述** `t60` 的报告或交件消息；**未引**我自己上一件的输出当证据。被复核的任何件**一字未改**（镜像内的改动全部在仓外，且每腿跑完即复原并核 `sha16`）。
> 本件体例：`§0` 快照 → 判词①–⑦ → `NOINFO` 具名 → 「推翻的话」。本席唯一写入 ＝ 本件。

---

## §0 快照（现取，逐条带 `ts=`）

| 项 | 现取值 | `ts=` |
|---|---|---|
| `HEAD` | **`2148443`** ＝ `21484439a0d0b23baf7101c1cf0f85d45db20e9a`（`docs(#81): t60 repair —— 两条已接线牙回绿…`，`2026-09-28T18:43:57+08:00`） | `2026-09-28T18:44:46.071940240+08:00` |
| `t60` 提交 `numstat` | `34 0 HANDOFF-NEXT.md`｜`110 0 P1-w4b-repair3-report.md`｜`11 4 handoff-machine-values-check.sh`｜`2 1 timestamp-order-check.sh` | `18:46:08.542753755` |
| 写域四件 | `handoff-machine-values-check.sh` ＝ **`b5c774843229d789`**／245 行｜`timestamp-order-check.sh` ＝ **`4483f12e222d98c8`**／222 行｜`HANDOFF-NEXT.md` ＝ **`41ea67b3323295da`**／560 行｜载体 `P1-w4b-repair3-report.md` ＝ **`f5cd0692671bb310`**／110 行（末行自证 `head -n -1` ＝ **`f18a225d5079cb86`**，我复算逐位相同） | `18:44:46.071940240` |
| 写前（`2148443^` ＝ `74c0d79`）两件牙 | `handoff…` ＝ **`cde265d7eaad36d5`**／238 行｜`timestamp…` ＝ **`05dbf89b6c5e776e`**／221 行 | `18:45:07.343638393` |
| `porcelain`（逐行点名） | ` M build/MilBridge/tools/defect-registry-declared.tsv`｜` M samples/WpfFeatureProbe/KNOWN-DEFECTS.md`｜`?? build/MilBridge/P1-task0201-criteria.md`｜`?? build/MilBridge/P1-task0201-recheck-report.md` ⇒ **四条均非 `t60`**（见观察 `O1`） | `2026-09-28T18:47:13.871695352+08:00` |

**仓外镜像（本判词全部腿的基座）**：`git archive 2148443 | tar -x` ⇒ `~/wv88y/t61/cur`（8384 件／244 M），**忠实性自证**：未改镜像与仓内两条牙输出**逐字 `IDENTICAL`**（`SHELL_QUOTE_SCAN=files=202 sh=113 py=89 anchors=strict lines=71673`／`PIPEFAIL_SIGPIPE=PASS … sites=100 …`；`ts=2026-09-28T18:45:08.656680013+08:00`）。另抽 `2148443^` 全树为 `~/wv88y/t61/pre60` 作**修前世界**。

---

## §1 判词① —— 两条牙的「绿」是真的：**成立**

**捕获式（`cmd >out 2>err; echo $?`，无管道取 `$?`），现取（`ts=2026-09-28T18:44:46.129499930+08:00`）**

- `QUOTE-TRAP`：**`rc=0`**（`stderr` `0` 行）｜`SHELL_QUOTE_TRAP=PASS reason=ok traps=0 files=202 sh=113 py=89 diag=76 allow=0`｜`^SHELL_QUOTE_HIT` **`0` 行**、站点（去重 `file:line`）**`0`**。
- `PIPEFAIL-SIGPIPE`：**`rc=0`**（`stderr` `0` 行）｜`PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 declared=0 files=113 sites=100 hit=0 low=10 diag=5 safe=85 runs=12`｜`^UNDECLARED_HIT` **`0` 行**。

**成对值（修前 ← 我自己重建的 `2148443^` 全树，`ts=2026-09-28T18:45:39.662413695+08:00` ⇄ 修后现取）**

| 量 | 修前（我重建） | 修后（现取） | `t60` 所报 | 我判 |
|---|---|---|---|---|
| `QUOTE-TRAP rc`／`traps`／站点 | `rc=1`／**`traps=4`**／**`2` 处**（`handoff…:94` `col=176`＋`179`；`timestamp…:112` `col=59`＋`67`） | `rc=0`／`traps=0`／`0` | `4→0`／`2→0` | **一致** |
| `PIPEFAIL rc`／`undeclared_hit`／`sites` | `rc=1`／**`1`**／**`101`** ＋ `UNDECLARED_HIT build/MilBridge/tools/handoff-machine-values-check.sh:96` | `rc=0`／`0`／**`100`**，点名行消失 | `1→0`／`101→100` | **一致** |

⇒ **`traps` 的口径我独立复核为「反引号个数」**：同一 `line=` 打两行 `HIT`、不同 `col=`（修前 `:94` 两行、`:112` 两行）⇒ 反引号 `4`／站点 `2`，与条目的并列口径**逐字相符**。

## §2 判词② —— 反极（**我自己造，三条腿**）：**成立**

> 目的：区分「问题真修了」与「牙被削弱了」。**三条腿全部只钉一个变量**，每腿跑完即从仓内复原并核 `sha16`（复原值逐次记录在案）。

- **腿 A／B（把修前形态按件撒回；`ts=2026-09-28T18:45:18.469449501+08:00`）**：镜像内**只**把 `handoff-machine-values-check.sh` 换成 `2148443^` 版（`cde265d7eaad36d5`）⇒ `QUOTE-TRAP rc=1 traps=2`（**只剩 `:94` 两反引号／1 站点**）∧ `PIPEFAIL rc=1 undeclared_hit=1 sites=101` ＋ `UNDECLARED_HIT build/MilBridge/tools/handoff-machine-values-check.sh:96`；**只**把 `timestamp-order-check.sh` 换成 `2148443^` 版（`05dbf89b6c5e776e`）⇒ `QUOTE-TRAP rc=1 traps=2`（**只剩 `:112`**）∧ `PIPEFAIL rc=0 … sites=100` ⇒ **`4 ＝ 2＋2`、只修一处仍红**（两半各自可归因，且 pipefail 那一半与 `timestamp` 件无关）。
- **腿 C（我自己把反引号加回**在**写后**形态上；`ts=2026-09-28T18:45:35.561256317+08:00`）**：把写后件里 `cell=#7` 的**代码行**（现 `:101`）包回反引号 ⇒ `rc=1`／`SHELL_QUOTE_HIT kind=DQ-BACKTICK file=build/MilBridge/tools/handoff-machine-values-check.sh line=101 col=87`／`col=95`／`SHELL_QUOTE_TRAP=FAIL reason=dq-backtick traps=2`（同腿 `PIPEFAIL` 仍 `PASS sites=100`）⇒ **牙没有被削弱**：它在写后的世界里照样抓得住新引入的反引号。
- **腿 D（只把「管道那一行」单行撒回旧形态；`ts=2026-09-28T18:47:07.084911472+08:00`）**：镜像内只把现 `:103` 的 `[[ "$c" =~ $REJECT_ERE ]]` 改回 `printf '%s' "$c" | grep -qE "$REJECT_ERE"`（其余保持写后）⇒ `PIPEFAIL rc=1 undeclared_hit=1 sites=101` ＋ `UNDECLARED_HIT build/MilBridge/tools/handoff-machine-values-check.sh:103`（行号随 `t60` 插入上移 `96→103`），**同腿 `HANDOFF_MV=PASS cells=9 equal=8 manual=1`** ⇒ 该站点**就是** `undeclared_hit` 的唯一来源，且该改写未伤该牙功能。
- **等价性探针（我自己跑，判定「语义不变」）**：`REJECT_ERE='HEAD|git log|git status|git rev-parse|git ls-remote'` 现取（件内唯一常量），对 `9` 组输入（含 `HEAD`／`git status`／`local HEAD == ls-remote == 88ab8414`／`DEFREG=PASS declared=222…`／空串 等）**`grep -qE` 与 `[[ =~ ]]` 判定逐组一致（9/9）**。

## §3 判词③ —— `H2`／`H3`／`H4` 逐条自算：**三条全部成立**

- **`H2`（自述 vs 实现）＝ 选「改自述」，我复核一致**：件内收尾行现取 `HANDOFF_MV_SELFTEST=PASS cases=5 pass=5 fail=0（闸含 S1–S4 ＋ S5 自主性腿；S6 为信息腿）`（捕获式 `rc=0`）；`S5` 在实现里**确实**参与 `np`／`nf`（现取代码：`if [ "$s5" = PASS ] && [ "$rc" = 0 ]; then np=$((np+1)); else nf=$((nf+1)); fi`），`S6` 只上屏不累加（`echo … case=S6 …`）⇒ **自述与实现现取一致**；运行时 `cases=5` 也自证闸含 `S1–S5`（旧自述「闸只含 S1–S4」与之矛盾，已改）。
- **`H3`（报头 vs `reason=`）＝ 选「改 `reason=`，不启用 `FOREIGN`」，我复核一致**：正极现取 `HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none`，`:4` 现为 `state=equal`、**无** `reason=`（旧串 `reason=foreign-lane-activity` 现取命中 `0`）。**自造反极（我造，镜像内把末条 `cell=#4` 更正行前缀改成 `DEFREG=FAIL`；`ts=2026-09-28T18:46:52.716423640+08:00`）** ⇒ `rc=1`／`HANDOFF_MV_HIT cell=#4 anchor=§7-3 登记册自洽 rule=route-file-changed-since-ts reason=cell-mismatch …`／`HANDOFF_MV=DIVERGED reason=cell-mismatch cells=9 equal=7 manual=1 mismatch=1 uncomparable=0 reasons=,#4:route-file-changed-since-ts` ⇒ **`reason=` token 与报头 token 同为 `cell-mismatch`**。
- **`H4`（`#8` 谓词判别力≈0）＝ 选(甲) 具名登记欠账，我复核「在场且可现算」**：`HANDOFF-NEXT.md` 内该段逐字在册，含「**`cell=#8` 自 `t57` 起不再承载『本波在飞』信号 …… **『在飞』信号自此无判据**，本欠账**具名在册**；下一波若要恢复该信号，**须先在仓内立『在飞』的权威机读定义**」；齿面读数为 `HANDOFF_MV_CELL cell=#8 … state=equal`＋`HANDOFF_MV_NOTE lane-activity=0（… **旁注，不进 equal 计数、不影响 rc**）` ⇒ **欠账的「无判据」事实可现算**（谓词＝`docs/WAVE81-PREREGISTRATION.md` 存在且非空）。**我判：不必推翻队长倾向 (甲)** —— 我现取未见任何「同义的稳定『在飞』权威机读读者」存在（`lane-activity` 本身只是旁注、`rc` 不受它影响），另立谓词确实只会再立一条脆弱判据。

## §4 判词④ —— `rc` 捕获式纪律条：**成立**

- **口径句逐字在场**：契约句（`凡报脚本 rc，一律**捕获式**取 —— cmd >out 2>err; echo $?；**不许**从管道末段取 $?（cmd | tail -3; echo $? 取到的是 tail 的 rc）`）在 `HANDOFF-NEXT.md` 内**逐字命中 `True`**（我以 Python 子串对拍，非肉眼），其后缀「本族已三次…三次都把真 `FAIL` 读成 `rc=0`」亦在场；编号现取为**第 `27` 条**。
- **条在位自检命令能重跑**：**首版**写的 `grep -c '本族已三次' …` ⇒ 我现取 **`3`**（**自指**；`t60` 自己也发现了并落 dated 更正）；**更正后**的命令 `` grep -c '不许\*\*从管道末段取' build/MilBridge/HANDOFF-NEXT.md `` ⇒ 我现取 **`1`**（＝其在册声明的值），且该命令字面带反斜杠 ⇒ **不自匹配** ✓。⇒ 「条在位自检」**现取可用**（首版自指已被如实入册并更正，属**只增不改**的 dated 更正）。
- **三例具名可核**：例① `build/MilBridge/P1-w4b-verify.md` ＝ **`6e6e5e876661f770`**／`412` 行（在册值逐位相同），被引句现取 `:359` 与在册逐字相符｜例② `build/MilBridge/P1-w4b-repair2-verify.md` ＝ **`ffb492e51c6fcde7`**／`240` 行（同），被引句现取 `:227` 相符｜例③ ＝ **`NOINFO`（具名）**：`t55` 载体现取 ＝ **`82af30b206a3f16d`**／`292` 行（**与在册引用逐位相同**），全文 `tail` 命中 **`1`** 处、且该处（`:121`）是**表格里被判命令的转述**、不是 `rc` 读数 ⇒ **「仓内无逐字引句」这一 `NOINFO` 如实**。
- **只加口径、未改任何牙**：纪律条**只落在** `HANDOFF-NEXT.md`（文本）；同一提交里两件牙的改动 = `H1` 修法（`--unified=0` 全线点名：反引号去掉／`printf | grep -qE` → `[[ =~ ]]`／`reason=` 换 token／收尾行自述），**没有任何牙为纪律条而改** ✓。`t60` 报告里 `tail` 命中 `3` 处**全部**是口径句与三例的**文本引用**，无一处用于取 `rc` ✓。

## §5 判词⑤ —— 未越域与不变量：**成立（附观察 `O1`）**

- **四条不变量现取**（`ts=2026-09-28T18:47:13.871695352+08:00`）：`^run_step "` ＝ **`61`**｜`--expect` ＝ **`233`**｜`# VERIFYALL-STEPS-DECL: 61 gen=#81`｜覆盖面（`infp.sh list | wc -l`）＝ **`233`** ✓。
- **两枚哨兵**：`cmp IDENTICAL`（`/tmp/bridge-frozen.flag` 与 `~/wfp-runs/bridge-frozen.flag` 各 `sha16 6cb3f97388c3c4dc`）⇒ **未写** ✓。
- **`src/**`／`build/*.Linux/**`**：与 `HEAD` 差 **`0`** 行 ✓；`t60` 提交对 `verify-all.sh`／`close-wave.sh`／`docs/ROUTES.md`／`KNOWN-DEFECTS.md`／`declared.tsv` 的 `numstat` **各 `0`** ✓。
- **观察 `O1`（他车道在飞，不是 `t60`）**：`KNOWN-DEFECTS.md` 现取 `9408c0fb0493dfff` ≠ `HEAD` 版 `58acad853a8dd7d5`；`declared.tsv` 现取 `cd31324cc7ed3965` ≠ `HEAD` 版 `850c185b2cf04aa9` —— 二者在 `porcelain` 里是 ` M`，**属他车道（`t59` 补记轮）在飞的写入**；`t60` 提交的 `numstat` 对这两件为 `0` ⇒ **「`t60` 未动」成立，「现值 ≠ `HEAD`」不归 `t60`**。

## §6 判词⑥ —— 模式守恒（两口径成对，写前 ⇄ 写后）：**成立**

| 件 | 写前（`2148443^`，取自仓外镜像＋`git ls-tree`） | 写后（现取） |
|---|---|---|
| `handoff-machine-values-check.sh` | 工作树 **`644`**／索引 **`100644`** | **`644`**／**`100644`** |
| `timestamp-order-check.sh` | **`755`**／**`100755`** | **`755`**／**`100755`** |
| `HANDOFF-NEXT.md` | **`644`**／**`100644`** | **`644`**／**`100644`** |
| `P1-w4b-repair3-report.md`（新件） | —（`HEAD^` 不存在） | **`644`**／**`100644`** |

⇒ **零模式位移**（`ts=2026-09-28T18:47:23.714731190+08:00`）；本会话 `D-G187` 两形态（提交级位移／工作树-索引长期分叉）**均未在这四件上出现**。

## §7 判词⑦ —— `rc` 读法抽查（不是从管道末段取）：**成立**

- `t60` 报告自带口径行逐字：「本件**一律捕获式取 `rc`**（`cmd >out 2>err; echo $?`）—— **不接管道**」；全文 `2>err`／`>out` 类命中 `10` 处，`tail` 命中 `3` 处**均为文本引用**（§4 已核）。
- **抽查四处我自己捕获式复算**：① 正极 handoff 牙 **`rc=0`**（`stderr 0` 行）＝在册值 ✓｜② `--selftest` **`rc=0`** ＋ `HANDOFF_MV_SELFTEST=PASS cases=5 pass=5 fail=0` ＝在册值 ✓｜③ **修前** quote 牙（`2148443^` 全树）**`rc=1`** ＝在册「腿 A `rc=1`」✓｜④ **修前** pipefail 牙 **`rc=1`** ＝在册值 ✓。

---

## `NOINFO`（具名，既不算绿也不算红）

1. `NOINFO(reason=未跑整趟门禁)`：两个门禁步的**端到端**绿未验（`verify-all` 一跑即构建 ⇒ `provider` 位位移）；本件只验两条牙本体与两条牙的判据面。
2. `NOINFO(reason=未逐笔重建站点来历)`：`handoff…:94` 那一处「`t57` 引入」的归属我**未逐笔重建**（历史件的同形行有多处、首现判据混杂）⇒ 我只能确证的归属面是：`timestamp-order-check.sh:112` 的 `date -d` 两反引号在 **`3aaaa3e`（W4a）时即已存在（既存）**，与在册一致；「本波引入」那一半**存疑不判**。
3. `NOINFO(reason=允许表未行使)`：`QUOTE-TRAP` 的允许表（写前 `allow=0`）本趟**未被使用**（走的是消除站点）⇒ 其豁免口径未复核（与 `t60` 自报同名同因）。
4. `NOINFO(reason=他车道在飞)`：`t59` 补记轮正在改 `KNOWN-DEFECTS.md`／`declared.tsv`（`porcelain` 点名）⇒ 其现值不属 `t60`、也不计入本判词；`t7` 的 `?? P1-task0201-criteria.md`／`?? P1-task0201-recheck-report.md` 同。
5. `NOINFO(reason=镜像非真树跑)`：全部反极与修前世界均在**仓外镜像**（`git archive` 全树）上跑；镜像忠实性已用「未改镜像 ⇄ 仓内输出逐字 `IDENTICAL`」自证，但它仍**不是**真树的同一 inode 集。

## 推翻的话 ＋ 结论

- **推翻 `t60` 的话**：**没有**。逐条独立复现：两条牙 `rc=0`／`traps=0`／站点 `0`／`undeclared_hit=0`／`sites=100`；成对值 `4→0`／`2→0`／`1→0`／`101→100`；`4 = 2+2` 由我自造两腿钉死；写后世界**新**插入反引号仍被抓（牙未被削弱）；`H2`／`H3`／`H4` 三处置我都能现取复算（`H3` 反极我自造得 `DIVERGED reason=cell-mismatch`＋`#4:route-file-changed-since-ts`）；纪律条逐字在场、更正后的自检命令 `=1`、三例 `sha16` 逐位相符、例③ `NOINFO` 如实；四条不变量／两哨兵／越域件／模式守恒全部成立。
- **结论**：判词①–⑦ **全部成立**；**观察 1 条**（`O1` 他车道在飞使 `KNOWN-DEFECTS.md`／`declared.tsv` 现值 ≠ `HEAD`，非 `t60`）；`NOINFO` 5 条具名。**`verdict = pass`**。

P1-W4B-REPAIR3-VERIFY: t61 attempt 2 | verdict=pass | 判词①-⑦全部成立｜推翻 none｜观察 1（O1 他车道在飞）｜NOINFO 5 | QUOTE-TRAP rc=0 traps=0 sites=0（修前我重建 2148443^：rc=1 traps=4 sites=2，:94 col176/179 + :112 col59/67）｜PIPEFAIL rc=0 undeclared_hit=0 sites=100（修前 rc=1 undeclared_hit=1 sites=101 点名 handoff…:96）｜反极三腿我自造：只回退 handoff⇒traps=2/pipefail 1 点名:96；只回退 timestamp⇒traps=2/pipefail PASS；写后插回反引号⇒FAIL 点名:101 col87/95；单行撒回管道⇒undeclared_hit=1 点名:103｜等价探针 grep -qE vs [[ =~ ]] 9/9 一致｜H2 现取 HANDOFF_MV_SELFTEST=PASS cases=5（S5 真参与 np/nf，S6 只上屏）｜H3 我自造反极⇒DIVERGED reason=cell-mismatch ＋ #4:route-file-changed-since-ts｜H4 选(甲) 欠账具名在册且可现算（未被推翻）｜第 27 条口径句逐字在场；首版自检命令自指（我现取 n=3），更正后 grep -c '不许\*\*从管道末段取'=1｜三例 sha16 6e6e5e876661f770/412:359、ffb492e51c6fcde7/240:227、例③ NOINFO 如实（t55 件 82af30b206a3f16d/292，tail 仅 1 处且为转述）｜不变量 61/233/61 gen=#81/233｜哨兵 cmp IDENTICAL 6cb3f97388c3c4dc｜src 与 build/*.Linux diff 0｜四件模式 644/100644、755/100755、644/100644、644/100644 与写前同｜HEAD 2148443｜载体 t60 P1-w4b-repair3-report.md f5cd0692671bb310/110 行 自证 f18a225d5079cb86 复算一致

# P1-dg187b 报告（`t59`／登记批补记轮）—— `D-G187` 第 `2` 形态 ＋ `O1`／`O2`／`O5`／`O6` 四条低危关账 ＋ `D-G186` 两条并列口径 ＋ 同趟 `--emit`

**本件口径（写死）**：**只增不改**（本件新建，落定后除末行自证不再改）；**本趟只做文本与口径补记，不做任何装置修法**；读数一律**捕获式取 `rc`**（`cmd >out 2>err; echo $?`，**不接管道** —— 交接件第 `27` 条）；每格带**亚秒 `ts=`**；**行号仅本次有效**；`NOINFO` 具名（§10）。

## 0. 一句话
`t56` 复核 `t53` 留下的 **1 条观察（O4）＋ 4 条 low（O1／O2／O5／O6）** 一期关账：`D-G187` 补了**第 `2` 形态**（工作树／索引长期分叉，`43/72`，git **不可见**）＋ 新增一条**模式两口径的口径句**；四条 low 各给了**可重跑的现取读数**；`D-G186` 正文补了**两条并列口径**（`traps=N` ＝ 反引号个数；两站点归属）。同趟 `--emit` 重发 `declared.tsv` ⇒ 两遍 `DEFREG=PASS`（`declared=222 route_ids=222`、`DECLDRIFT=0`）。

## 1. 写域（**只有三件**，零越域）与写入前后成对读数
| 件 | 写前 `sha16`／行 | 写后 `sha16`／行 | `stat -c %a` | `git ls-files -s` |
|---|---|---|---|---|
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `58acad853a8dd7d5`／`3788` | **`9408c0fb0493dfff`／`3845`** | `644` | `100644` |
| `build/MilBridge/tools/defect-registry-declared.tsv` | `850c185b2cf04aa9`／`232` | **`cd31324cc7ed3965`／`232`** | `644` | `100644` |
| `build/MilBridge/P1-dg187b-report.md`（本件） | —（新建） | 见末行自证 | `644` | 未入索引 |

- **写前快照**（`ts=2026-09-28T18:44:40.831+0800`）：KD `hl=1`／`wt=644`／`idx=100644`／`3788` 行／`58acad853a8dd7d5`；`declared.tsv` `hl=1`／`644`／`100644`／`232` 行／`850c185b2cf04aa9`；`# DECL-GEN = (--emit) 2026-09-28 18:13:34 +0800`。
- **写后快照**（`ts=2026-09-28T18:47:05.722+0800`）：KD `644`／`100644`／`3845` 行／`9408c0fb0493dfff`；`declared.tsv` `644`／`100644`／`232` 行／`cd31324cc7ed3965`／`^ID` 行 `222`。
- **模式守恒自证（两口径成对，写前写后逐位相同）**：KD `644`／`100644`；`declared.tsv` `644`／`100644`；本件 `644`／未入索引。**本趟零模式位移**（本趟登记的正是这一族）。
- **红线**：`docs/ROUTES.md`／`verify-all.sh`／`build/close-wave.sh`／`src/**`／`build/MilBridge/tools/**`（装置件）**一字未动**；`git status --porcelain` 现取恰 `2 M`（本趟两件）＋ `2 ??`（**别的车道**的 `build/MilBridge/P1-task0201-criteria.md`／`P1-task0201-recheck-report.md`，未读未改）＋本件新建 1 件；未 `git add`／`commit`／`push`。

## 2. ① `O4` → `D-G187` 补「第 `2` 形态」（并入同一条目，**不另起号**）
**本席现取复算**（`ts=2026-09-28T18:44:50.624+0800`；件集 ＝ `build/MilBridge/tools/*.sh`，共 `72` 件）：
- 工作树 `stat -c %a`：`600×15`／`644×13`／`711×28`／`755×16`；`git ls-files -s`：`100644×28`／`100755×44` ⇒ **工作树四档、索引两档**。
- **交叉表**：`100644 ⇒ 600` **`15`**｜`100755 ⇒ 711` **`28`**（合 **`43/72`**）｜`100644 ⇒ 644` **`13`**｜`100755 ⇒ 755` **`16`**（规范档 **`29/72`**）。
- **补①**：`git config core.fileMode` ＝ **`true`**；**「索引 `x` 位 vs 工作树 `x` 位」不一致件数 ＝ `0`** ⇒ `porcelain` 干净**不是** git 不看模式，而是分叉**恰落在 `x` 位之外**。
- **补②（`rc=126` 机制，仓外副本；`ts=2026-09-28T18:45:06.853+0800`）**：
```
A stat600 ./x.sh    → rc=126  stderr_lines=1  err="bash: 行 1: ./x.sh: 权限不够"
B stat600 bash x.sh → rc=3    stderr_lines=0
C stat755 ./x.sh    → rc=3    stderr_lines=0
D stat755 bash x.sh → rc=3    stderr_lines=0
```
  ⇒ **`bash <件>` 调用式把 `600` 完全掩盖**；与第 `1` 形态的 `rc=126` **同一机源**。
- **仓内调用式样例（逐字，现取 `:1200`，仅本次有效）**：`run_step "SELFDESC-WIRING" bash build/MilBridge/tools/selfdescription-wiring-check.sh`。
- **实例件（`ts=2026-09-28T18:44:55.952+0800`）**：`build/MilBridge/tools/selfdescription-wiring-check.sh` ＝ `stat -c %a` **`600`**／`git ls-files -s` **`100644`**／`182` 行；与 `05148bb^` 对拍 `git diff --numstat` **无输出（差 `0` 行）**。
- **措辞（逐字入册）**：第 `2` 形态 ＝ **「工作树与索引长期分叉（`600` 档 `15` 件／`711` 档 `28` 件，合 `43/72`；仅 `29/72` 处在规范档），其中 `600` 档对直接执行是真故障。」**；`711` 档**在直接执行上是通的、不是坏档**（**未**读成坏档）。
- **边界**：**只登记、不修**（修它要动 `72` 件模式且无判据需求）；第 `1`／第 `2` 形态**都保留**（前者 git 可见、后者不可见）。
- 🔴 **新增口径句（逐字入册）**：**「凡报『模式无位移』，必须同时给 `stat -c %a` 与 `git ls-files -s` 两口径；两口径不一致必须分别报，不许只报其一然后说『无位移』；『`git status` 干净』不得当模式守恒的机器证。」**

## 3. ② `O1` 关账：`D-G184` 补「最小复现的**命令原文**」（`ts=2026-09-28T18:45:26.280+0800`）
- **正极**：`bash build/MilBridge/tools/selfdescription-wiring-check.sh >out 2>err; echo $?` ⇒ **`rc=0`**、`err` `0` 行：
```
SELFDESC_WIRING=PASS examined=72 wired=50 unwired=22 undeclared=51 fails=0 run_step=61
SELFDESC_FILE file=build/MilBridge/tools/sentinel-spec-check.sh header=selfdesc-wired run_step=hit verdict=PASS rule=-
SELFDESC_FILE file=build/MilBridge/tools/timestamp-order-check.sh header=selfdesc-wired run_step=hit verdict=PASS rule=-
SELFDESC_FILE file=build/MilBridge/tools/wave-push.sh header=selfdesc-wired run_step=hit verdict=PASS rule=-
```
  ⇒ 三件**各得一条 `verdict=PASS rule=-`**、**无一条 `FAIL` 逐件行**（上文所缺的正是这段**命令原文**）。
- **反极（仓外副本）**：`mkdir -p <沙箱>/build/MilBridge/tools` ＋ `cp -p verify-all.sh <沙箱>/` ＋ `cp -p build/MilBridge/tools/wave-push.sh <沙箱>/build/MilBridge/tools/` ＋ 往副本**件头加一行行首无 `#`** 的「本件未接线（不进 verify-all）」＋ `bash build/MilBridge/tools/selfdescription-wiring-check.sh --root <沙箱> >out 2>err; echo $?` ⇒ **`rc=1`**、`err` `0` 行：
```
SELFDESC_FILE file=build/MilBridge/tools/wave-push.sh header=selfdesc-notwired run_step=hit verdict=FAIL rule=forward-selfdesc-notwired-but-wired
SELFDESC_ROSTER examined=1 wired=1 unwired=0 undeclared=0 selfdesc_notwired=1 selfdesc_wired=1 fails=1
SELFDESC_WIRING=FAIL examined=1 wired=1 unwired=0 undeclared=0 fails=1 run_step=61
```
  ⇒ **点名该件与 `rule=forward-selfdesc-notwired-but-wired`**；夹具全在仓外，**仓内残留 `0`**。

## 4. ③ `O2` 关账：`D-G185` 「逐条点名」与 `…` 省略不一致 ⇒ **补全 12 个 `tag`**
**本席现取**（`ts=2026-09-28T18:45:30.505+0800`；**帧仍在长 ⇒ 过程值、非结账值**）：`~/t7-runner/runs.tsv` ＝ **总行 `215`／数据行 `214`／唯一 `tag` `202`／重复 `tag` `12` 个**（上文现象行的 `171／170／158／12` 是 `18:13:34` 当时值）。**12 个重复 `tag` 逐条（无省略）**：`A6C`／`W126`／`W127`／`W128`／`W129`／`W130`／`W131`／`W132`／`W133`／`W134`／`W135`／`W136`（每个 ×2）。**重跑命令原文**：`tail -n +2 ~/t7-runner/runs.tsv | cut -f1 | sort | uniq -cd | awk '{printf "%s×%s ", $2, $1}'` ⇒ 现取原样 `A6C×2 W126×2 W127×2 W128×2 W129×2 W130×2 W131×2 W132×2 W133×2 W134×2 W135×2 W136×2`。⇒ **自称与现场自此一致**（省略号只留在上文原句里，本行给全集；**上文一字未删**）。

## 5. ④ `O5` 关账：`D-G184` 里三个 `sha16` 的**口径 ＝ 整件**（`ts=2026-09-28T18:45:16.709+0800`）
| 件 | **整件** `sha256` 前 `16` 位（现取） | 行 | 与上文所载对照 |
|---|---|---|---|
| `build/MilBridge/tools/sentinel-spec-check.sh` | `7887de15d07b1f0d` | `119` | **逐位相同** |
| `build/MilBridge/tools/wave-push.sh` | `bb7440867a646b32` | `143` | **逐位相同** |
| `build/MilBridge/tools/timestamp-order-check.sh` | **`4483f12e222d98c8`** | `222` | 上文所载 `05dbf89b6c5e776e` 是 `t54` 当时值 ⇒ **已过期**（`t60` 改了该件），**以现取为准**（第 `24` 条） |

**口径（写死）**：三处一律是**整件** `sha256` 的前 `16` 位（`sha256sum <件> | cut -c1-16`），**不是**「该行内容的前 `16` 位」。

## 6. ⑤ `O6` 关账：第 `5` 实例所引 `declared=218` 系当时值 ⇒ 「以现取为准 ＋ `ts=`」
**本席现取**（`ts=2026-09-28T18:45:53.302+0800`）：`DEFREG=PASS` 且 **`declared=222 route_ids=222`**（捕获式 `rc=0`／`stderr` `0` 行；命令 `bash build/MilBridge/tools/defect-registry-check.sh | tail -1`）。**`+4` 归因（两条现取）**：`05148bb`（`t53` 登记批）同趟入册 `D-G184`／`D-G185`／`D-G186`／`D-G187` ⇒ `^ID` 行数 `05148bb^` ＝ **`218`** ⇒ `05148bb` ＝ **`222`**；该四号在 `05148bb^` 现取出现 **`0`** 次／在 `05148bb` 现取出现 **`4`** 次。原句（`declared=218`）**保留为当时读数**，判据以现取为准。

## 7. ⑥ `D-G186` 正文补**两条并列口径**（源：`t58` 现场 ＋ `t60` 修法；现取 `ts=2026-09-28T18:46:01.962+0800`）
- **A（计数语义）**：`shell-quote-trap-check.sh` 的 **`traps=N` 里的 `N` ＝ 反引号个数、不是行数** —— 同一条 `echo "…"` 行里**两个反引号各打一行** `SHELL_QUOTE_HIT`（同 `line=`、不同 `col=`）。
- **B（站点归属，与 A 并列）**：写前 `4` 个反引号落在 **`2` 处**：① `build/MilBridge/tools/handoff-machine-values-check.sh:94`（**`t57` 引入**）② `build/MilBridge/tools/timestamp-order-check.sh:112`（**既存**，自 `3aaaa3e`／W4a 起逐字相同）；**两处已由 `t60` 去掉**（改成不带反引号的 `（cell=#7 是推送面/流水线敏感量 ⇒ 不许呈机读形态）` 与 `（date -d 解不出 ⇒ 不判）`）。
- **并列的成对现值**：写前（同件集沙箱，`ts=2026-09-28T18:39:42.341+0800`）`SHELL_QUOTE_TRAP=FAIL reason=dq-backtick traps=4` ⇒ **反引号 `4` 个／站点 `2` 处**；写后（现取）`SHELL_QUOTE_TRAP=PASS reason=ok traps=0` ⇒ **`0` 个／`0` 处**（`rc=0`、`stderr` `0` 行、`^SHELL_QUOTE_HIT` `0` 行）。
- **旁证**：`PIPEFAIL-SIGPIPE` 写前 `rc=1`／`undeclared_hit=1`／`sites=101` ＋ 点名 `handoff-machine-values-check.sh:96` ⇒ 写后（现取）`rc=0`／`PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 declared=0 files=113 sites=100 hit=0 low=10 diag=5 safe=85 runs=12`、点名行 `0` 行。

## 8. 同趟 `--emit` 与两遍 `DEFREG`（原样）
`ts=2026-09-28T18:46:53.693+0800`：`bash build/MilBridge/tools/defect-registry-check.sh --emit > build/MilBridge/tools/defect-registry-declared.tsv 2>err; echo $?` ⇒ **`rc=0`**、`err` `0` 行。**两遍** `bash build/MilBridge/tools/defect-registry-check.sh >out 2>err; echo $?` ⇒ **`rc=0`／`rc=0`**、`err` 各 `0` 行；两遍尾三行**逐字相同**：
```
DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN keys=-
DEFREG_DECLDRIFT_KEYS=-  # 机读差集键行（零漂移给 -；`?` = 声明件里读不到锚行）
DEFREG=PASS declared=222 route_ids=222（每个声明编号在其 req 的每个 route 文件里都在 ∧ **现场 route 出现集未超出 req**；无未声明编号）
```
**`DECL-GEN` 同趟刷新**：`# DECL-GEN = (--emit) 2026-09-28 18:46:53 +0800`（写前 `18:13:34`）；**自洽**：`# DECL-ANCHORS … KD=9408c0fb0493dfff …` ＝ 本件写后 `sha16`（**逐位相同**）。

## 9. 不变量与红线（现取，`ts=2026-09-28T18:47:05.722+0800`）
`^run_step "` ＝ **`61`**｜首行 `# VERIFYALL-STEPS-DECL:`（`:72`）＝ **`61 gen=#81`**｜覆盖面 ＝ **`233`** ＝ `[42] --expect` **`233`**｜`# VERIFYALL-STEP-NAMES:` **`61`** 项 ⇒ **四条不变量未变**｜两枚哨兵 `cmp` **`rc=0`（IDENTICAL）**、各 `6cb3f97388c3c4dc`（**未写**）｜`REPORTID=PASS files=215 ids=2118 declared=222`（`rc=0`）｜**未跑整趟 `verify-all`**。

## 10. `NOINFO`（具名，既不算绿也不算红）
1. `D-G187` 第 `2` 形态**只登记不修**（修它要动 `72` 件模式且无判据需求）⇒ 「修后是否无分叉」**未验**。
2. `D-G185` 台账读数**系过程值**（同一会话内两次现取 `171 → 215`）⇒ **不是结账值**；以该台账作分母的结论仍须按该条口径重报。
3. **未跑整趟 `verify-all`**（会构建）⇒ 端到端绿**未验**，本趟只验规则面与两枚哨兵。
4. `O5` 里 `t54` 当时值 `05dbf89b6c5e776e` **已无法再复现为现取**（该件被 `t60` 改）⇒ 旧值**只作留档**。
5. 本趟**未复核** `D-G186` 的「允许表」机制（写前读数 `allow=0`，本趟未使用）⇒ 其豁免口径**未验**。

## 11. 自伤与当场更正（如实记，全部零损伤）
1. **`rc=126` 首版读数被命令替换吃掉**：首版写成 `./x.sh >o1 2>e1; echo "… rc=$?"`（同一行里先跑 `$(stat -c %a x.sh)`）⇒ 命令替换把 `$?` 重置成 `0`，**读出 `rc=0`（假绿）** ⇒ 已改为「**先 `rc=$?` 存变量，再打印**」，重跑得 **`rc=126`**（`ts=2026-09-28T18:45:06.853+0800`）。**与本会话新立第 `27` 条同族**（读 `rc` 的取法本身会伪造绿）。
2. **`grep -c` 返回 `0` 短路 `&&` 链**：诊断行用 `grep -c '^D-G' … && …` ⇒ 命中 `0` 时期后命令**没跑**（零损伤，已用 `;` 重跑并把 `^ID` 作计数口径）。
3. **本件前两处措辞**（`D-G185` 现象行引用的当时值、`O5` 的行号）在落定前当场核正，未写进仓的错值（本件为新建件，无「改既有件」动作）。
⏪ **本件自证（末行；口径 `head -n -1 build/MilBridge/P1-dg187b-report.md | sha256sum | cut -c1-16`）**：`287c937100a82de1`（**整件全文 `sha256` 只在交件消息里给**，按本区第 `24` 条）。

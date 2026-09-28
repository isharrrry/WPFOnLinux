# P1-w4b-repair3 报告（`t60`）—— 两条已接线牙回绿（`QUOTE-TRAP`／`PIPEFAIL-SIGPIPE`）＋ `H2`／`H3`／`H4` ＋ 「`rc` 一律捕获式取」入册

**口径**（本件自带，写死）：本件**一律捕获式取 `rc`**（`cmd >out 2>err; echo $?`）—— **不接管道**（本会话「从管道末段取 `$?`」已咬三次 ⇒ 本趟把它配号入册，见 §4）；每个读数带**亚秒 `ts=`**；**只增不改**（本件新建，落定后不再改，除末行自证）。**`NOINFO` 具名**（§9，既不算绿也不算红）。

## 0. 一句话
本波**两条已接线牙在本波变红**的根因都已消除：`QUOTE-TRAP` 反引号 `4 → 0`（站点 `2 → 0`）、`PIPEFAIL-SIGPIPE` `undeclared_hit 1 → 0`；`H2`／`H3`／`H4` 各自二选一处置完毕；「`rc` 捕获式取」已作为**第 `27` 条**入册 `build/MilBridge/HANDOFF-NEXT.md`。四条不变量未变、两枚哨兵未写、未跑整趟门禁、未动写域外任何件。

## 1. 写域与落点（**只动 3 件**；写域外零改动）
| 件 | 写前 `sha16`／行 | 写后 `sha16`／行 | `stat -c %a` | `git ls-files -s` |
|---|---|---|---|---|
| `build/MilBridge/tools/handoff-machine-values-check.sh` | `cde265d7eaad36d5`／`238` | **`b5c774843229d789`／`245`** | `644` | `100644` |
| `build/MilBridge/tools/timestamp-order-check.sh` | `05dbf89b6c5e776e`／`221` | **`4483f12e222d98c8`／`222`** | `755` | `100755` |
| `build/MilBridge/HANDOFF-NEXT.md` | `3044dd66c84cc903`／`526` | **`41ea67b3323295da`／`560`** | `644` | `100644` |
| `build/MilBridge/P1-w4b-repair3-report.md`（本件） | —（新建） | 见末行自证 | 见 §7 | 见 §7 |

**写前备份**（一律**在任何写之前** `cp -p`，`cmp` 逐位 `IDENTICAL`）：`~/w281-scribe/bak/handoff-machine-values-check.sh.pre-t60`（`cde265d7eaad36d5`）／`~/w281-scribe/bak/timestamp-order-check.sh.pre-t60`（`05dbf89b6c5e776e`）／`~/w281-scribe/bak/HANDOFF-NEXT.md.pre-t60`（`3044dd66c84cc903`）。写前硬链接数 `stat -c %h` 三件均 ＝ `1`；落盘一律 `temp + rename`（保留模式）。

## 2. 两条牙的成对读数（**原样输出**，每格带亚秒 `ts=`）

### 2.1 `QUOTE-TRAP`：**四腿归因**（同一件集，每腿只钉一个变量）
沙箱件集 ＝ `find "$ROOT" \( -name '*.sh' -o -name '*.py' \) -type f`（减 `upstream/`／`obj/`／`.artifacts/`／`__pycache__/`）⇒ **`202` 件（`sh=113 py=89`）**，与现盘读数**同件集**（现盘 `files=202 sh=113 py=89`）。

**腿 A（写前两件，`QT_ROOT` 沙箱）** —— `ts=2026-09-28T18:39:42.341+0800`；`bash build/MilBridge/tools/shell-quote-trap-check.sh >/tmp/pre.out 2>/tmp/pre.err; echo $?` ⇒ **`rc=1`**、`stderr` **`0`** 行：
```
SHELL_QUOTE_TRAP=FAIL reason=dq-backtick traps=4 files=202 sh=113 py=89 diag=76 allow=0
SHELL_QUOTE_HIT kind=DQ-BACKTICK file=build/MilBridge/tools/handoff-machine-values-check.sh line=94 col=176
SHELL_QUOTE_HIT kind=DQ-BACKTICK file=build/MilBridge/tools/handoff-machine-values-check.sh line=94 col=179
SHELL_QUOTE_HIT kind=DQ-BACKTICK file=build/MilBridge/tools/timestamp-order-check.sh line=112 col=59
SHELL_QUOTE_HIT kind=DQ-BACKTICK file=build/MilBridge/tools/timestamp-order-check.sh line=112 col=67
```
**腿 B（只把本牙换写后；`timestamp-order-check.sh` 仍写前）** —— `ts=2026-09-28T18:39:48.260+0800`：**`rc=1`／`traps=2`**，命中**只剩** `timestamp-order-check.sh:112`（`col=59`＋`col=67`）。
**腿 C（只把 `timestamp-order-check.sh` 换写后；本牙仍写前）** —— 同 `ts`：**`rc=1`／`traps=2`**，命中**只剩** `handoff-machine-values-check.sh:94`（`col=176`＋`col=179`）。
**腿 D（两件写后＝现盘）** —— `ts=2026-09-28T18:41:20.675+0800`：**`rc=0`**、`stderr` `0` 行、`^SHELL_QUOTE_HIT` **`0` 行**：
```
SHELL_QUOTE_TRAP=PASS reason=ok traps=0 files=202 sh=113 py=89 diag=76 allow=0
```
⇒ **`4 = 2(本牙) + 2(TSORDER)`、`D = 0`**：**两站点各 2 个反引号、两处都必须修**（只修一处仍红）—— 四腿钉死，非推断。
**自测（现盘）**：`bash build/MilBridge/tools/shell-quote-trap-check.sh --selftest >out 2>err; echo $?` ⇒ **`rc=0`**（末行 `ST_ATTEST=PASS … sha16=39a2e2cdf1948675（自测期间本件未变 ⇒ 读数可归因）`）。
**口径并列（写死，免后人按行数去找并不存在的第 3／4 处）**：**`traps=N` 的 `N` ＝ 反引号个数、不是行数** —— 写前 `traps=4` ＝ **反引号 `4` 个／「件:行」站点 `2` 处**（**同一行里两个反引号各打一行 `SHELL_QUOTE_HIT`**：同 `line=`、不同 `col=`）。**归属并列**：`handoff-machine-values-check.sh:94` ⇒ **`t57` 引入**；`timestamp-order-check.sh:112` ⇒ **既存**（自 `3aaaa3e`／W4a 起逐字相同）。

### 2.2 `PIPEFAIL-SIGPIPE`：同一件集沙箱的写前 ＋ 现盘写后
**写前**（`PP_ROOT` 沙箱，件集 `files=113` 与现盘相同）—— `ts=2026-09-28T18:39:48.260+0800`；`bash build/MilBridge/tools/pipefail-sigpipe-check.sh >/tmp/prepf.out 2>/tmp/prepf.err; echo $?` ⇒ **`rc=1`**、`stderr` `0` 行：
```
PIPEFAIL_SIGPIPE=FAIL undeclared_hit=1 decl_stale=0 files=113 sites=101 hit=1 low=10 diag=5 safe=85 runs=12
UNDECLARED_HIT build/MilBridge/tools/handoff-machine-values-check.sh:96
```
**写后**（现盘）—— `ts=2026-09-28T18:41:20.675+0800` ⇒ **`rc=0`**、`stderr` `0` 行：
```
PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 declared=0 files=113 sites=100 hit=0 low=10 diag=5 safe=85 runs=12
```
⇒ `undeclared_hit 1→0`、`sites 101→100`、`hit 1→0`，`UNDECLARED_HIT … :96` **消失**。
**归因腿（只钉一个变量）**：写前沙箱（两件皆写前）⇒ `hit=1` 且点名 `:96`；写后沙箱（两件皆写后）⇒ `hit=0`／`sites=100` ⇒ **该站点即本牙 `:96` 那一处**（`ts=2026-09-28T18:39:56.154+0800`，`PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 declared=0 files=113 sites=100 …`）。
**处置 ＝ 「改写」，不是「声明」**：① 该牙的声明表（`DECL`）**内嵌在 `pipefail-sigpipe-check.sh` 本体**，而**本趟写域不含那颗牙**（写域外一律不动）⇒ 声明路径在本趟**走不通**；② 该站点**结构上是真形态**（左端可多次 `write()`、末段 `grep -q` 命中即退出 ⇒ `set -o pipefail` 下管线 `rc` 可被翻成 `141`）⇒ 改成 **bash 内建** `[[ "$c" =~ $REJECT_ERE ]]`（**无管道、无子进程**）。
**判据语义不变的证据（自造反极腿）** —— `ts=2026-09-28T18:39:56.154+0800`：把某格命令改成 `git status --porcelain | wc -l` ⇒ `rc=1`（原样：`HANDOFF_MV_HIT cell=#5 anchor=§7-5 步数 rule=cell-not-comparable-to-pipeline-state reason=not-comparable cmd=git status --porcelain | wc -l`）⇒ **拒绝族仍照抓、点名该格**。
**自测（现盘）**：`--selftest` ⇒ **`rc=0`**，末行 `SELFTEST=PASS total=15 pass=15 fail=0`。

### 2.3 两处静默丢字（同趟被修掉的那一处）
写前 `handoff-machine-values-check.sh:94` 那句里的 `` `#7` `` 会被 **命令替换**吃掉（`#` 起头 ⇒ 连 `stderr` 都 `0` 行）⇒ 原样输出的判词**缺字**；去掉内层反引号后该句完整上屏（见 §2.1 腿 D 所属牙的现盘读数）。

## 3. `H2`／`H3`／`H4` 处置（都给了原样输出）
- **`H2`（自述 vs 实现）⇒ 改自述**。理由：`S5` 在 `np`／`nf` 上累加是**有意的** —— 它正是「**自测不依赖活件**」这条判据本身（沙箱内放陈旧活件副本 ⇒ `--selftest` 仍须 `PASS`）；降级成信息腿 ＝ **自废该判据**。原样（`ts=2026-09-28T18:38:42.274+0800`，`bash …handoff-machine-values-check.sh --selftest >out 2>err; echo $?` ⇒ `rc=0`、`stderr 0` 行）：
```
HANDOFF_MV_SELFTEST=PASS cases=5 pass=5 fail=0（闸含 S1–S4 ＋ S5 自主性腿；S6 为信息腿）
```
- **`H3`（报头 vs `reason=`）⇒ 改 `reason=`，不启用 `FOREIGN`**。理由：该格差异源**在本件写域内**（route 件内容变了）⇒ 与 `FOREIGN` 的定义（差异源**不在**本件写域）**不符**；报头 `HANDOFF_MV=DIVERGED reason=cell-mismatch` 才对。自造反极腿（把在册最后一条 `cell=#4` 更正行的**前缀**改成 `DEFREG=FAIL`）—— `ts=2026-09-28T18:39:16.784+0800`，原样：
```
HANDOFF_MV=DIVERGED reason=cell-mismatch cells=9 equal=6 manual=1 mismatch=2 uncomparable=0 reasons=,#1:covered-file-changed-since-ts,#4:route-file-changed-since-ts
HANDOFF_MV_HIT cell=#4 anchor=§7-3 登记册自洽 rule=route-file-changed-since-ts reason=cell-mismatch in-repo=DEFREG=FAIL declared=222 route_ids=222（…）
```
⇒ **逐格 `reason=` 与报头同 token**（`rule=` 保留规则名）。
- **`H4`（`#8` 谓词判别力≈0）⇒ 选(甲) 具名登记欠账**（已逐字落 `HANDOFF-NEXT.md`）。理由：`t57` 换 `#8` 谓词是为**去掉「全机脏件数」这条假红源**（实测 3 分 25 秒内摆动 3 次），而「有没有链在跑」**仓内无权威机读读者**（`HANDOFF_MV_NOTE lane-activity=<n>` 只是旁注、不进 `equal`、不影响 `rc`）⇒ 另造一个「在飞」谓词只会再立一条**脆弱判据**；门禁判据只能是**被门禁覆盖世界的函数**。**欠账（逐字入册）**：「`cell=#8` 自 `t57` 起不再承载『本波在飞』信号 —— 现判据＝『本波预登记件存在且非空』，**只在** `docs/WAVE81-PREREGISTRATION.md` 被删/清空时翻红，**判别力≈0**；**『在飞』信号自此无判据**，本欠账**具名在册**；下一波若要恢复该信号，**须先在仓内立『在飞』的权威机读定义**（进程面或 `POST.done` 面）＋**正反两腿**，再改判据。」
  现盘 `#8` 读数（原样）：`HANDOFF_MV_NOTE lane-activity=0（= 写域面之外脏件数；**旁注，不进 equal 计数、不影响 rc**）`；`#8` 逐格 `state=equal`（现值 `in-wave-81-registered`）。

## 4. 纪律条入册（`HANDOFF-NEXT.md` 第 `27` 条）
编号现取：本区编号块最后一条 ＝ 第 `26` 条（`t48` 落，内容锚「dated 接线账 · W4b 合波」）⇒ 本条 ＝ **第 `27` 条**。**口径句（逐字入册）**：**「凡报脚本 `rc`，一律**捕获式**取 —— `cmd >out 2>err; echo $?`；**不许**从管道末段取 `$?`（`cmd | tail -3; echo $?` 取到的是 `tail` 的 `rc`）。本族已三次（`t50`／`t55` 各一次读 `tail` 的 `rc`、队长早前一次），三次都把真 `FAIL` 读成 `rc=0`。」**
**条在位自检（更正后版本）** —— `ts=2026-09-28T18:41:11.856+0800`：`grep -c '不许\*\*从管道末段取' build/MilBridge/HANDOFF-NEXT.md >out 2>err; echo $?` ⇒ **`rc=0`**、`n=1`、`err 0` 行（`ts=2026-09-28T18:41:20.675+0800` 复跑仍 `n=1`）。
**三例具名**：
- **例①（`t50`，`scout`）**：出处件 `build/MilBridge/P1-w4b-verify.md`（整件 `sha16` ＝ `6e6e5e876661f770`，`412` 行；该句现取 `:359`）—— 逐字引：「**（b）我另跑两颗可能被反引号咬的牙**（自证不是全域污染）：`bash build/MilBridge/tools/shell-quote-trap-check.sh` ⇒ `rc=0`（末行 `SHELL_QUOTE_DIAGN kind=PY-BACKTICK-FILE n_files=76 n_lines=2032`）」⇒ 该 `rc=0` 取自**管道末段**；本席**不经管道**现取同一牙（写前）＝ `rc=1` ＋ `traps=4` ⇒ **真 `FAIL` 被读成 `rc=0`**。
- **例②（`t58`，`scout` 自纠并写死机理）**：出处件 `build/MilBridge/P1-w4b-repair2-verify.md`（整件 `sha16` ＝ `ffb492e51c6fcde7`，`240` 行；该句现取 `:227`）—— 逐字引：「那个 `rc=0` **是管道末段 `tail` 的 `rc`，不是该牙的 rc**」。
- **例③（`t55` 一次 ＋ 队长早前一次）**：**`NOINFO`（具名）** —— 出处＝会话/任务记录面，**仓内无载体句**：本席现取核查 `t55` 载体 `build/MilBridge/P1-w4b-repair-verify.md`（整件 `sha16` ＝ `82af30b206a3f16d`，`292` 行）⇒ 全文 `tail` 仅 `1` 处（`:121`，且是**被判命令**的转述列、非 `rc` 读数）⇒ **无逐字引句、无 `sha16` 可给**；队长那次只见于消息面。
**本趟自己从头执行该条**：本件每个 `rc` 都是 `cmd >out 2>err; echo $?` 取得（**无一处经管道**），且每处都给了 `stderr` 行数。

## 5. 契约 verify 五条（原样，`ts=2026-09-28T18:41:20.675+0800`，`HEAD=74c0d79`，全部捕获式）
1. `bash build/MilBridge/tools/shell-quote-trap-check.sh >out 2>err; echo $?` ⇒ **`rc=0`**、`err 0` 行、`0` 行 `HIT`；`SHELL_QUOTE_TRAP=PASS reason=ok traps=0 files=202 sh=113 py=89 diag=76 allow=0`。
2. `bash build/MilBridge/tools/pipefail-sigpipe-check.sh >out 2>err; echo $?` ⇒ **`rc=0`**、`err 0` 行；`PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 declared=0 files=113 sites=100 hit=0 low=10 diag=5 safe=85 runs=12`。
3. `grep -c '^run_step "' verify-all.sh` ⇒ **`61`**；`grep -n '^# VERIFYALL-STEPS-DECL:' verify-all.sh | head -1` ⇒ `72:# VERIFYALL-STEPS-DECL: 61 gen=#81   ← …（后略，行内含 `t48`／W4b 的三步账）` ⇒ **两值相等（`61`）**；`# VERIFYALL-STEP-NAMES:` 现取 `:124`／**`61`** 项。
4. `bash ~/w153a/bin/infp.sh list | wc -l` ⇒ **`233`**；`grep -n 'fp-manifest-step.sh --expect' verify-all.sh` ⇒ `1199:run_step "FP-MANIFEST-TEETH" bash build/MilBridge/tools/fp-manifest-step.sh --expect 233` ⇒ **两值相等（`233`）**。
5. `cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag; echo $?` ⇒ **`rc=0`（`IDENTICAL`）**，两枚各 `sha16` ＝ `6cb3f97388c3c4dc` ⇒ **哨兵未写**。

## 6. 不变量与红线（现取）
`DEFREG=PASS declared=222 route_ids=222`（`ts=2026-09-28T18:41:26.886+0800`，`rc=0`）＋ `DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN keys=-`｜`REPORTID=PASS files=213 ids=2107 declared=222 glob=build/MilBridge/*report*.md`（`rc=0`）｜**未跑整趟门禁**｜`git status --porcelain` 现取恰 **`3 M`（本趟三件）＋ `1 ??`（`build/MilBridge/P1-task0201-criteria.md`，**别的车道**的件、未读未改）**｜`src/**`／`build/*.Linux/**`／`docs/ROUTES.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/tools/defect-registry-declared.tsv` **一字未动**｜仓内临时件残留 **`0`**（`find . -name '*.t60tmp' -o -name '*.pre-t60'` ＝ `0`）｜未 `git add`／`commit`／`push`。

## 7. 模式守恒自证（两口径成对；写前写后**逐位相同**）
`handoff-machine-values-check.sh`：`stat -c %a` ＝ `644`／`git ls-files -s` ＝ `100644`（写前后同）｜`timestamp-order-check.sh`：`755`／`100755`（写前后同）｜`HANDOFF-NEXT.md`：`644`／`100644`（写前后同）｜本件（新建）：`644`／`100644`（新件默认档、**非** `100755`，且**不接线**）。本趟**无任何模式位移**。

## 8. 自伤与当场更正（如实记）
1. **第 `27` 条首版自检命令自指**：首版写 `grep -c '本族已三次' …`，该四字串**也出现在那条命令的字面里** ⇒ 现取 `n=2`（**不是 `1`**）。已**dated 追加更正**（同件，原句一字未删），更正后命令 `grep -c '不许\*\*从管道末段取' …`（命令字面带反斜杠 ⇒ **不自匹配**）⇒ **`n=1`**，更正前后各复跑一次。口子与第 `24` 条同族（**自指**）。
2. **沙箱复现而非「照抄派单读数」**：写前的 `QUOTE-TRAP`／`PIPEFAIL-SIGPIPE` 两行 `FAIL` 汇总**我在同件集沙箱里自己跑出来**（`files=202`／`files=113` 与现盘一致 ⇒ 件集相同），故 §2 的写前值**全部可复算**；我没有把任何既有列印当读数。

## 9. `NOINFO`（具名，既不算绿也不算红）
1. **未跑整趟 `verify-all`**（一跑就构建 ⇒ `provider` 位位移）⇒ 两个门禁步的**端到端**绿**未验**；本趟只验**两件牙本体**与**两条牙的判据面**。
2. **例③的两次咬伤**（`t55`／队长）：**仓内无载体句** ⇒ 给不出逐字引与 `sha16`（§4）。
3. **`SHELL_QUOTE_TRAP` 的允许表**（`allow=0`）机制**本趟未使用**（走的是消除站点）⇒ 其豁免口径**未复核**。
4. **`cell=#4` 的计数不是被判量**（`t57`／G2 写死的口径句②）：在册更正行里的计数写错**不被判**（只进 `HANDOFF_MV_DIAG` 诊断列，现取 `declared_inrepo=222 route_ids_inrepo=222`）。本趟**不放松**该判据、只统一 `reason=` 与报头；**该边界具名在册**（若要收紧须另立一波）。
5. **`cell=#7`（推送面）／`cell=#9`（九值需重建波）** 的既有 `NOINFO` 边界**未变**。

## 10. 写域边界（越域一律未做，具名交接）
队长信里另有两条**不在本单写域**的事项：② 把「`traps=N` ＝ 反引号个数」与「两站点归属」两个口径写进 **`D-G186` 的登记正文**（那是 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`，**本单 `outOfScope`**）⇒ 本趟**只把两个口径并列写进了 `HANDOFF-NEXT.md`**（§2.1 与 §4 同块），**`KD` 一字未动**；`KD` 那面归登记批任务（`t59`）。另有 `t59` 的机器值／模式族补记同样**不在本单写域**。
⏪ **本件当场更正（自证基线，`t60`）**：首版自证值 `f5f72c7d1d60244e` 是**在末行仍是正文时**用 `head -n -1` 算出的（**少算了最后一行正文**）⇒ 与正文不符；已按「**先落正文 ⇒ 再算 `head -n -1` ⇒ 末行只放自证**」重算，**现值即末行所示**（本件自伤第 `3` 条，零损伤）。
⏪ **本件自证（末行；口径 `head -n -1 build/MilBridge/P1-w4b-repair3-report.md | sha256sum | cut -c1-16`）**：`f18a225d5079cb86`（**整件全文 `sha256` 只在交件消息里给**，按本区第 `24` 条）。

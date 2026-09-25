# 波 `#73` 报告 —— `TASK-0726`「把**静默 SEGV** 那条腿的**产出端**收进仓 ＋ 收编同形副本」

> 车道 **W171A**（唯一写者）｜`state=DONE`｜`CRITERIA_FIRST=yes`（判据正本 `docs/WAVE73-PREREGISTRATION.md`）
> 权威树 `$R`（**不是 git 仓**）｜报告为**纯 Markdown**（无 JSON／schemaJson／UI 卡片）

## §1 我做了什么（逐条命令 ＋ 现算读数）

| # | 动作 | 现算读数 |
|---|---|---|
| 1 | 8 份同形副本**现取** | `w128a/bin/one128.sh b5217b83870a4d9c`（**未动**）｜`w118a/bin/one118.sh 13674b647160f2fc`｜`wc06/probe/one_wc06.sh 46d5e2c3cf9296cc`｜`wc07/bin/one128g.sh 1e09bf458957596e`｜`wc08/bin/one_wc08.sh 20782a3b21aec293`｜`wc11/bin/one_wc11.sh 8eee56d895cc21e3`｜`w155a/w65d109/bin/leg.sh 15a427eca2e83f03`｜`w159a/bin/leg.sh 64d027a98c537b0b`（`%h` 全 1） |
| 2 | 新建**产出端** | `build/MilBridge/tests/SilentHitProbe/run-silenthit-legs.sh` **`64574cfe296dac19`**（`%h=1`；`bash -n` ok；`grep -c "$HOME/w"` = **0**） |
| 3 | 新建**剔除集** | `build/MilBridge/tests/SilentHitProbe/silenthit-trim.tsv` **`d2bcd611f2506ce0`**（22 行：6 条 `trimmed=yes` ＋ 16 条 `trimmed=no`；`%h=1`） |
| 4 | 改 `build/close-wave.sh` | `247cb3d16e2a5392` → **`086f89e13d8e5522`**（`fp_inputs()` 白名单 **+2 行**） |
| 5 | 改 `verify-all.sh` | `66da0964f462bb7c` → **`f9bc5bca5be3d7f2`**（第 `[42]` 步 `--expect 192 → 194`；头注释口径句 ＋ 新 `DECL` 行，**不动步数**） |
| 6 | 新建预登记 | `docs/WAVE73-PREREGISTRATION.md` **`99eb0543345da4fc`**（`PREREG4=NA rc=0`） |
| 7 | 7 份副本标废 | 改前→改后：`13674b647160f2fc→0ded290a970290ff`｜`46d5e2c3cf9296cc→76ea3f451e260fd6`｜`1e09bf458957596e→64ecd6e0b4f5e42b`｜`20782a3b21aec293→9357444fcad7dbe6`｜`8eee56d895cc21e3→e20b95ea2261fe3d`｜`15a427eca2e83f03→6402d8aa7f583580`｜`64d027a98c537b0b→ece8c0b3a30b1d00`；`one128.sh` 改前==改后 |

## §2 判据与两极化（含判否结果）

**判据本体（唯一实现 = 产出端 `analyse_rundir()`）**：`APP_TEXT_BYTES_TRIMMED == 0 ∧ STACKOVF == 0 ∧ SEGV_BRANCH ∈ {rc139,fate,term,stop-signo11}`；两条前置闸（`UNDECLARED_TAG_LINES > 0`／`phase == teardown`）⇒ 该腿 `NOINFO`。**两个数都印**。

| 腿 | 命令 | 原始机读末行（节选） | 判否结果 |
|---|---|---|---|
| **R1** 真静默 SEGV | `--app-cmd <真 C 程序 volatile int *p=0; *p=1>`，`:236` | `LEG … rc=139 APP_TEXT_BYTES=43 APP_TEXT_BYTES_TRIMMED=0 TRIM_GATE=ok STACKOVF=0 SEGV_BRANCH=rc139 FAMILY=139-segv phase=nav undeclared=0 HIT=yes` ＋ `SILENT_SEGV_HIT=yes …` | **红签名必现 ⇒ 成立** |
| **R2** 重放历史真现场 | `--replay ~/w128a/frozen/W077` | `LEG … rc=1 APP_TEXT_BYTES=0 APP_TEXT_BYTES_TRIMMED=0 … SEGV_BRANCH=stop-signo11 … HIT=yes` | **红签名必现 ⇒ 成立**；且与 `#68` 参考实现的重放读数**逐字相同** |
| **C1** 真进程不崩 | `--app-cmd <quiet-ok.sh>`，`:236` | `LEG … rc=0 APP_TEXT_BYTES=41 APP_TEXT_BYTES_TRIMMED=41 … SEGV_BRANCH=none … HIT=no` | **不得打红 ⇒ 成立** |
| **C2** **真 WPF 应用活腿** | `--app-cmd 'dotnet HandyControlDemo.dll'`（私有应用目录，`:237`，**走 `~/heavy-slot.sh`** `held=47s`） | `LEG … rc=124 APP_TEXT_BYTES=242 APP_TEXT_BYTES_TRIMMED=0 … SEGV_BRANCH=none FAMILY=alive phase=alive-after-recipe … HIT=no` | **不得打红 ⇒ 成立**；与在册 `live-legs-green.tsv` 十条**逐格相同** |

**产出端 `--selftest`：8/8 PASS**（S2 真静默 SEGV 档必 HIT／S3 活腿档必 NOT-HIT／S4 未声明 tag 必 NOINFO／S5 已声明 tag **成对**／S6 **尾部空格 needle 成对**（无空格 23 B 不剔／有空格 0 B 必剔）／S7 环境闸反极性 `rc=9`／S8 单变量断言成对）。
**单变量构造**：`diff_n == 1` ∧ 唯一差异路径 == 声明的变体路径 ⇒ 才跑；构造后**去硬链接化**并**两次**断言 `%h == 1`。

## §3 关键读数表（值 ＋ 出处命令）

| 项 | 值 | 出处 |
|---|---|---|
| 冻结 | **`FREEZE_RC=0`**；基线 `2eb64610f65a0d07` → **`f747350edf97a74a`**；`gen=#73` | `~/w171a/w73/w73freeze/logs/w73-freeze.DONE` |
| 🔴 `#72` 余账 | `⟦PREVCHECK⟧ gen=#73 prev=#72 … sha16=2eb64610f65a0d07` ＋ **`PREVCHECK=PASS gen=#73 keys=7 base=2eb64610f65a0d07`** | 同上（**生产路径**） |
| 九位 | 只有环成员 `pf` 位移 `147aac2dbbc6a0d8 → 4c45500d413e31e7`（同尺寸 6,123,520 B）⇒ **表外位移 0** | 同上 |
| 覆盖面 | `192 → 194`（`coverage_n=194 artifact_n=0 missing_n=0 stderr_bytes=0` ∧ **现算** `FPHYG_COVERAGE_N=194`） | 冻前 `verify-all` 日志 |
| `inputs_fp` | `999791b4…` → **`17f0abdb41764ac91e3c728d57136193c3cc483a2a8680d61e93206503da5aad`**（整波自印 == 独立复算 `would_be_fp` **逐位相同**） | 整波日志 ＋ `fp-manifest-step.sh` |
| 步数 | `42 → 42`（首行 `DECL` `42 gen=#73` == 现取 `grep -c '^run_step "'` = 42） | `verify-all.sh` |
| 链 | wave ✅（`held=183s`）｜gateapp ×2 `rows=6/6 全 PASS` ∧ `tiers_passed=2/2` ∧ `acceptance=2/2` ∧ `GATE_LINES_IDENTICAL=yes`（`:236`） | `~/w171a/w73/logs/` |
| 冻前 | gate1／gate2／pre **各 `42 ✅/0 ❌`** ∧ `结论：✅ 全部通过` | `w73-{gate1,gate2,pre}-20260926-003352.log` |
| 冻后 | ×2 **各 `42 ✅/0 ❌`** ∧ `结论：✅ 全部通过` ∧ `BASELINESHA=PASS live=f747350edf97a74a` ∧ `DEFREG=PASS declared=173 route_ids=173`（无 `DECLDRIFT` 红） ∧ `[12] coverage_n=194` ∧ `[42] declared_expect=194` ∧ `[39] SILENTHIT=PASS` ∧ `[17] hit=0` ∧ `QUOTE_TRAP traps=0 files=178` ∧ 判词行**逐字相同** | `w73-{gate1,gate2}-20260926-012906/014438.log` |
| 冻结器 | `dfe84694c6cf7a25` → **`439236d6d2504d9a`**（前像 `w27-freeze.py.bak-w73` ＋ `versions/w73-439236d6d2504d9a`） | `~/w21-verify/` |
| 备份成对 | 手工 == 冻结器自留 == `2eb64610f65a0d07` | `w73freeze/B.pre-freeze.#73.bak` |

## §4 我没做到的（逐条 `NOINFO` 及原因）
1. **`NOINFO`：现场形态判不了 `term`／`stop-signo11`** —— 本产出端**现场不跑 gdb** ⇒ 现场可观测的第三支只有 `rc139`／`fate`；`term`／`stop-signo11` 只在 `--replay`（吃既有 `gdb.txt`）形态可判（R2 就是这么判的）。**这是射程，不是缺陷。**
2. **`NOINFO`：本波不给任何率／上界** —— 「现件代静默 SEGV 率」需要 `≥131` 腿（2.26%）量级的分母，属台账层；本波只把**一趟怎么被观测**变成机读行。
3. **`NOINFO`：`--legs-from` 未接进 `verify-all`** —— 门禁里跑的是判据端的 `--cases` 那条路；**产出端与判据端的接线**属下一步。本波只保证「产出端在树、能被真跑、表列与判据端相容」。
4. **`NOINFO`：`--app-cmd` 形态的读数不是 WPF 应用本体的读数** —— R1／C1 属该形态（应用面被调用方替换）；只有 **C2** 是真应用面。
5. **`UNWIRED` 仍在（如实）**：产出端**在仓内**，但 `verify-all.sh` 里**没有任何一步调用它**（判据口径限定到代码形状 `grep -cE '^[[:space:]]*run_step .*silenthit' verify-all.sh` = **0**）⇒ **不许**把第 `[39]` 步 `SILENT-HIT-V2` 的 `--cases PASS` 读成「现件代已复现／已清零」。

## §5 自伤（如实留档；都被自己的守卫/自检当场咬住）
1. **冻结守卫先咬到我自己**：`w73-record.txt` 里我写了 `{FREEZE_SHA}`／`{PREV_SHA}` 两个**不在工具 `fmt` 表内**的占位符 ⇒ `template-placeholder-not-in-fmt-table` ⇒ `STOP`、**基线件零字节改动**（复核仍 `2eb64610f65a0d07`、`gen=#72`），改字面量后 `RC=0`。
2. ⭐ **PRE 快照取在整波重建中间** ⇒ `pf` 是**中间态** `4c45500d413e31e7`（不是 `#72` 冻后值 `147aac2dbbc6a0d8`）⇒ 若照此冻结，`changed==['pf']` 会因「拿中间态当开工前值」而**碰巧成立**＝**假读数**（判据变成「跟一个随机中间态比」）。改用**上一代冻结块**做权威来源重建，并在冻结器注释里留档。**口径句：凡「与上一代比」的判据，输入一律取上一代冻结块，不许取整波重建途中的活树快照。**
3. `ARM_DIFF` 最初直接数 `diff` 的 `<>` **行数** ⇒ 一件内容变了给**两行** ⇒ "只差一件"被数成 2 ⇒ 断言**恒假**（`--selftest` S8a 咬到，改为去重后的相对路径数）。
4. 相对路径归一化的 `sed` 写成两条表达式 ⇒ 第二条把第一条已成功的替换**再匹配一次** ⇒ 差异集**恒空**（S8b 从"拒绝"退化成 `diff_n=0`，咬到）。
5. `--app-cmd` 形态的应用 cwd 不存在 ⇒ `app.rc=90`（已加 `mk_arm_dir()`）；应用被信号打死时**内层 shell** 往屏上打"段错误"⇒ 污染 ≤2 KB 摘要（已内层 `exec 2> wrapper.err`）。
6. 车道侧 `w73-freeze.sh` 一行 `say "…**\`#72\` 余账兑现**…"` 里写了**双引号内的裸反引号** ⇒ bash 真做命令替换（`语法错误：未预期的文件结束符`），诊断文字被吃掉（`QUOTE-TRAP` 同族；**车道侧件，不在 `$R` 扫描面内**），`rc` 不受影响。

## §6 大白话小结（≤5 行）
1. 从前「静默 SEGV」只有**判据**在仓里，**产数的腿**散在 8 份车道副本里 —— 本波把产出端做成仓内**唯一**一件，并把它连同**剔除集**一起纳入指纹覆盖面（192 → 194）。
2. 三件病被治好：剔除口径**单一来源**、两臂**只差一件**才跑（且不许共享 inode）、环境变量**没收到就拒跑**。
3. 4 条腿全真跑：真崩的给红签名、真活的**不给**红签名；其中一条是**真 WPF 应用**，读数与在册活腿台账逐格相同。
4. 冻结这一刻 `PREVCHECK=PASS` 由**生产路径**亲手打出 ⇒ `#72` 那笔「接线后还没真冻过」的余账**兑现**。
5. 最值得记的一条自伤：**判据不能跟"整波重建途中的活树"比** —— 那会让它**碰巧成立**。

`W171A: state=DONE wave=#73 steps=42 gen=#73 sha16=f747350edf97a74a`

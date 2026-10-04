# P1-DG184-VERIFY —— `t53`（四条登记批 `D-G184`／`D-G185`／`D-G186`／`D-G187` ＋ 同趟 `--emit`）**独立复核判词**

> 复核者 `verifier`（任务 `t56`，attempt 2）。**一切现取自算、自己造夹具重跑**；**未复述** `t53` 的报告或交件消息；**未引**我自己上一件的输出当证据。
> 我的唯一写入 ＝ 本件；夹具全在仓外 `~/wv88y/t56/**`。`~/t7-runner` 全程**只读**（未动台账、未发信号、未重跑）。

---

## §0 快照（现取，逐条带 `ts=`）

| 项 | 现取值 | `ts=` |
|---|---|---|
| `HEAD` | **`05148bb`** ＝ `05148bb3c28839a81c7fb873204eb192695c84d0`（提交时刻 `2026-09-28T18:15:10+08:00`） | `2026-09-28T18:15:58.707118845+08:00` |
| 被判三件 | `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` ＝ **`58acad853a8dd7d5`**／`3788` 行／`644`｜`build/MilBridge/tools/defect-registry-declared.tsv` ＝ **`850c185b2cf04aa9`**／`232` 行／`644`｜`build/MilBridge/P1-dg184-report.md` ＝ **`0048c5ddf0e34804`**／`19` 行／`644` | 同上 |
| 相关牙 | `defect-registry-check.sh` ＝ `243e1879dcc78ee9`／428 行／索引 `100755`／工作树 `755`｜`selfdescription-wiring-check.sh` ＝ `fbba3de1d9fb84b8`／182 行／索引 `100644`／**工作树 `600`**（观察 `O4`，非本笔） | `2026-09-28T18:16:05.422519317+08:00` |
| 越域件 | `HANDOFF-NEXT.md` ＝ `b81567e26c29a527`／516 行｜`verify-all.sh` ＝ `742175bffd5a175d`｜`build/close-wave.sh` ＝ `69c39feabe148c62`｜`docs/ROUTES.md` ＝ `26841d6ed6fe8085`／838 行 —— **四件逐件 `== HEAD`**，`src/**` 与 `HEAD` 差 **`0`** 行 | `2026-09-28T18:18:06.784802717+08:00` |
| `porcelain`（逐行点名） | `?? build/MilBridge/P1-task0201-criteria.md`（`t7`）｜`?? build/MilBridge/P1-w4b-verify.md`（`t50`／`t54` 车道）｜`?? build/MilBridge/P1-w4b-repair-verify.md`（同上） —— **均不属 `t53`、不属本笔**；`build/MilBridge/tools` 下未跟踪件 **`0`**（仓内残留 `0`） | `2026-09-28T18:18:36.059948607+08:00` |

---

## §1 判词① —— 占用与配号：**成立**

- **未被占用（独立口径：上一笔的状态里四号零命中）**：`git grep -E 'D-G18[4-7]' 05148bb^ -- .` 命中行数 ＝ **`0`**；其中四个 route 件内命中 ＝ **`0`**（现取 `ts=2026-09-28T18:18:36.059948607+08:00`）。四条标题形态正则 `^### 🆕 \*\*\`D-G18[4-7]\`\*\* —— ` 命中 **`4`**。
- **`declared.tsv` 最大号**：**`187`**（`grep -oE 'D-G[0-9]+' | sort -n | tail -1`）≥ `187` ✓；数据行 `222`（`grep -c '^ID'`）／非空行 `232`。
- **四行逐字（内容锚，不按行号）**：`ID\tD-G184\treq=KD\tpresent=KD`／`D-G185`／`D-G186`／`D-G187` 同形（现取四行原文）。
- **规则 `③` ＋ `③′`（两向都不超出）**：现场出现集现取 —— `KNOWN-DEFECTS.md`（`KD`）**`4`** 行、`docs/CURRENT-STATE.md`（`CS`）**`0`**、`handoff.md`（`HO`）**`0`**、`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（`AB`）**`0`** ⇒ `req=KD ≡ present=KD ≡` 现场出现集 ✓（两向均不超出）。全表口径两遍现跑同值：`DEFREG=PASS declared=222 route_ids=222`（两值相等）＋ `DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN keys=-`。

## §2 判词② —— 四条体例与八段：**成立（内容层；段名不齐如实点名，`段序` 不作判据）**

- **形态**：四条均为 `### 🆕 **\`D-G###\`** —— …`（正则命中 `4`）✓。
- **八段在场（以内容判，不以段名判）**：`现象`／`判据（机器）`／`🔴 口径句（永久，逐字）`／`责任归属`／`边界`／`同族` **四条全部在场**；`根因` 四条在场（`D-G186` 写在其**标题句**里，未独立成行）；机器读数四条在场（`D-G186`／`D-G187` 并进 `现象` 行）；`最小复现` `D-G185` 独立成段且给**可重跑命令原文**（我原样跑通），`D-G184`／`D-G186`／`D-G187` 并进 `现象`／`机器证`／`真咬现场` 行（配方可复现 —— 我逐条自己复现成功，见 §3／§5／§6）；`在册实例逐条点名` `D-G184`／`D-G186`／`D-G187` 逐条点名（含件名＋原件行＋`sha16`）。
- **如实点名的三处 `low`（不构成不成立）**：
  - **`O1`**：`D-G184` **无独立「最小复现」段**，复现配方并入「机器证」行（配方逐字给出、无命令原文）⇒ 我按其配方复现成功（§3），判 `low`。
  - **`O2`**：`D-G185` 的「现象」行写 `A6C×2`＋`W126×2 … W136×2` 且**自称「逐条点名」**，实际用 `…` **省略了 9 个 `tag`** ⇒ 与同句自称不符（同条的「最小复现」命令可现取补全 —— 我跑出 12 个逐条，见 §4）⇒ 判 `low`。
  - **`O3`**：`D-G185`／`D-G187` 两条**无「反极」侧**（`D-G187` 仓内**无牙**可反极 —— 现取 `tools/*.sh` 无一引用 `100755`／`ls-files -s`、`verify-all.sh` `61` 步中步名含 `MODE`／`CHMOD` 者 **`0`**；条目的边界段如实写「不做修法…不声称全仓无其它模式位移」）⇒ 判观察，不判红。

## §3 判词③ —— `D-G184` 条目（反极我自己重跑）：**成立**

- **正极（现取，仓内直跑）**：`rc=0`｜`SELFDESC_ROSTER examined=72 wired=50 unwired=22 undeclared=51 selfdesc_notwired=3 selfdesc_wired=18 fails=0`｜`SELFDESC_WIRING=PASS examined=72 wired=50 unwired=22 undeclared=51 fails=0 run_step=61` —— 与条目所引**逐字同值**（`ts=2026-09-28T18:16:43.815663860+08:00`）。
- **反极（**我自己造**，仓外；最小世界：根内只放 `wave-push.sh` 1 件 ＋ 自造 `verify-all.sh` 两条 `run_step`）**：件头插一行**行首无 `#`**的「本件未接线（不进 verify-all）」⇒ `rc=1`｜`SELFDESC_FILE file=build/MilBridge/tools/wave-push.sh header=selfdesc-notwired run_step=hit verdict=FAIL rule=forward-selfdesc-notwired-but-wired`（**点名该件与该 `rule`**）｜`SELFDESC_WIRING=FAIL examined=1 wired=1 undeclared=0 fails=1`（＝条目数值）。**全镜像反极**（72 件）亦 `fails=1`。**镜像忠实性自证**：未改镜像与正极输出逐字 `IDENTICAL`（`diff` 无输出）⇒ 反极的差异只来自我插入的那一行。
- **修前世界（我独立重建：`git archive 3aaaa3e^ build/MilBridge/tools verify-all.sh` 抽到仓外再跑其中的牙）**：`examined=68 wired=47 unwired=21 undeclared=53 selfdesc_notwired=3 selfdesc_wired=12 fails=0`／`run_step=58` ⇒ 与条目「修前 `53`／`12`／`47`」**逐值相同** ⇒ 成对 `53→51`／`12→18`／`47→50` **我可复算** ✓（`ts=2026-09-28T18:16:55.929169785+08:00`）。
- **修前原文逐字**（`git show 3aaaa3e^:<件>` 现取，三行）：`sentinel-spec-check.sh` 件头内「（`t23`／W3a；**本件不接线**，接线归 W4）」｜`wave-push.sh` 件头内「**【不接线】**本件**未被 `close-wave.sh`／`verify-all.sh` 调用**（接线归 W4）。」｜`timestamp-order-check.sh` 件头内「（`t27`／V2 收口；…；**本波不接线** —— 接线归 W4）」—— 与条目所引一致；三件修前件头对字样表两串 `grep -c` **各 `0`**（`未接线`／`不进 verify-all`／`已接线` 全 `0`）⇒ `nw=0 ∧ w=0` ✓。
- **修后现取**：三件件头各含 `已接线`（牙逐件给 `header=selfdesc-wired`），且 `grep -c "^run_step .*<basename>" verify-all.sh` 三件**各 `1`** ✓。
- **观察 `O5`（措辞歧义，不判红）**：条目把 `7887de15d07b1f0d`／`bb7440867a646b32`／`05dbf89b6c5e776e` 紧贴在「件头 `:4`／`:21`／`:5`」之后 ⇒ 若读作**行** hash 则**不复现**（我实算：含换行 `11ccc8fe2c1dc5be`／`e19903d22c352261`／`af451a6a48f92a6c`；去换行 `c01102a4514e082c`／`b3d05f3731ff695d`／`4e115b721604f264`）；**实为整件 `sha16`** —— 现取 `git show HEAD:<件> | sha256sum | cut -c1-16` 三值与之**逐位相同** ⇒ 值可复现、口径歧义，判 `low`。

## §4 判词④ —— `D-G185` 条目：**成立（读数带 `ts=`，声明为过程值）**

- **台账只读现取**（`ts=2026-09-28T18:17:54.481858107+08:00`；**过程值、不是结账值** —— 同一条复核内我的另一次现取已由 `172` 行涨到 `177` 行，链在 `A7` 段仍在跑）：总行 **`177`**／数据行 **`176`**／唯一 `tag` **`164`**／`sha16` **`5aa5770a40e2fc58`**。
- **重复 `tag` 逐条点名（我跑条目给的可重跑命令原文，原样输出）**：`A6C×2 W126×2 W127×2 W128×2 W129×2 W130×2 W131×2 W132×2 W133×2 W134×2 W135×2 W136×2`（**`12` 个，全部列出**）。
- **`logs/chain.log`**：`grep -c 'A6 start='` ＝ **`2`** ✓；`CHAIN_ABORTED` 命中 ＝ **`0`** ✓。
- **`chain.pid` 与活进程不一致（该观察如实入册）**：`chain.pid` 现取内容 ＝ `610180`，`/proc/610180` **不存在 ⇒ `DEAD`**；`ps` 现取（只读）活着的链 ＝ **`1717529 bash bin/chain.sh`（`ALIVE`）** ⇒ 条目「pid 件未随重启更新」的观察**成立且已入册** ✓。
- **受影响面那句 `NOINFO` 的如实性（单独判）**：条目逐字写「…**都须按上条口径重报**；⚠️ **本席未复核那两处结论** ⇒ 记 **`NOINFO(reason=未复核该两处结论)`**」⇒ **既没读成「无影响」，也没读成「已污染定论」**，而是「须按去重口径重报 ＋ 未复核」 ⇒ **如实** ✓。指认对象在仓内有载体（`t7` 判据件现取含 `N=175`／`0/175`／`1.6973%`／`单侧 95%` 字样）✓。
- **`O2` 同 §2**：现象的 `…` 省略与「逐条点名」自称不符（`low`）。

## §5 判词⑤ —— `D-G186` 条目（成对我自己重跑）：**成立**

- **`bash -n` 过 ∧ 执行期 `stderr` 非 0（我自己造夹具）**：副本件头插一行**行首无 `#`**、含反引号与 `${HOME}` 的自述 ⇒ `bash -n` **`rc=0`**，真跑 **`rc=3` ＋ `2` 行 `stderr`**（首行 `…/bare.sh: 行 47: wpw: 未找到命令` ⇒ **反引号命令替换真被执行**）⇒ 成对成立 ✓。修后三件现取 `stderr` ＝ **`0／0／0`**（`sentinel-spec-check.sh` `rc=0`／`timestamp-order-check.sh` `rc=0`／`wave-push.sh --dry-run` `rc=0`，各自 `2>err`）；`build/MilBridge/tools/*.sh` **`bash -n` `72/72` 全过** ✓。
- **修前 `7–8` 行我自己重建**（`git archive fcb5cd4^` 全树到仓外后真跑）：`sentinel-spec-check.sh` **`7`** 行／`timestamp-order-check.sh` **`7`** 行／`wave-push.sh`（`--dry-run`）**`8`** 行 ⇒ 与条目「各打 `7–8` 行」一致 ✓；且「行首无 `#`」自述行落在 **`:4`／`:5`／`:21`**（`git show fcb5cd4^:<件>` 现取，与条目点名的行位相同）；首行样例 `…/sentinel-spec-check.sh: 行 4: t48: 未找到命令`。
- **第 5 实例成对（我自己重跑，只读旧件 `~/w281-scribe/bak/defect-registry-check.sh.pre-t49`）**：① **缺省**（件被拷离仓内原路径）⇒ `rc=2` ＋ `DEFREG=NOINFO reason=no-declaration decl-file-missing decl=/home/links-dev/w281-scribe/bak/defect-registry-declared.tsv`（**假红**）✓；② **显式注入全量 `DRC_*`（含 `DRC_DECL`）** ⇒ `rc=0` ＋ `DEFREG=PASS declared=222 route_ids=222` ⇒ **机制成立**（未注入 `DRC_DECL` 时仍 `NOINFO` —— 这一步我自己先踩过，口径＝「全量」须含 `DRC_DECL`）。
- **观察 `O6`（时点值，不判红）**：条目第 5 实例引的 `declared=218` 是**当时值**；现取为 **`222`** ＝ `218 ＋ t53` 本趟自己新增的四号，且未标「以现取为准／`ts`」（第 `24` 条形态）⇒ 判 `low`。

## §6 判词⑥ —— `D-G187` 条目：**成立（且族仍开口）**

- **两处 `mode change` 方向相反（现取）**：`git show 3aaaa3e --summary` ⇒ 三行 `mode change 100755 => 100644`（`sentinel-spec-check.sh`／`timestamp-order-check.sh`／`wave-push.sh`）；`git show fcb5cd4 --summary` ⇒ 三行 `mode change 100644 => 100755` ✓。**现取**：`git ls-files -s` 三件均 **`100755`** ＋ `stat -c %a` 各 **`755`** ✓。
- **「根因＝`os.replace` 不保模式」是机理断言、族仍开口**：条目边界段逐字「**不做修法**（把「模式守恒」写进统一落盘器或做成牙 ⇒ 另排波次）；本条只覆盖在册三件实例的位移与恢复，**不声称全仓无其它模式位移**」⇒ **保留了族仍开口** ✓；我另取机器证：`tools/*.sh` 内**无一**件引用 `100755`／`ls-files -s`，`verify-all.sh` `61` 步中 `MODE`／`CHMOD` 步名 **`0`** ⇒ **仓内确无模式守恒牙**，条目未把它写成「已由牙看着」✓。

## §7 判词⑦ —— 四条口径句：**成立（四条均「可现算」，无「只在场不可算」者）**

| 条目 | 口径句落点（内容锚） | 是否可现算（我的现算证据） |
|---|---|---|
| `D-G184` | `KNOWN-DEFECTS.md` 的 `### 🆕 D-G184` 条目内以 `- 🔴 **口径句（永久，逐字）**：`「凡『接线自述』类判定…」起首那一行 | **可**：字样表两常量现取（`SD_NOTWIRED`／`SD_WIRED` 各命中 `1`）＋扫描面 glob ＋ 牙的 `undeclared=`／`selfdesc_*=` 计数 ⇒ §3 三腿 |
| `D-G185` | 同件 `### 🆕 D-G185` 条目内 `- 🔴 **口径句（永久，逐字）**：`「凡以跑批台账作分母…」起首那一行 | **可**：总行／唯一 `tag`／重复 `tag` 逐条 ＋ 去重保留最后一次 ⇒ §4 我跑条目原样命令得 12 个 |
| `D-G186` | 同件 `### 🆕 D-G186` 条目内 `- 🔴 **口径句（永久，逐字）**：`「凡把『结构检查通过』当某件的机器证…」＋「凡引旧版判据件当对照…」两条 | **可**：`bash <件> 2>err` 断 `stderr` 空＋`DRC_*` 成对 ⇒ §5 两对我自己跑 |
| `D-G187` | 同件 `### 🆕 D-G187` 条目内 `- 🔴 **口径句（永久，逐字）**：`「凡改写既有件，必须显式保全文件模式…」起首那一行 | **可**：`git ls-files -s` 模式格 ＋ `stat -c %a` 成对 ⇒ §6 与 §10 |

## §8 判词⑧ —— 同趟性与三态：**成立**

- **同趟**：`declared.tsv` 首行原文 `# DECL-GEN = (--emit) 2026-09-28 18:13:34 +0800`（`DECL-GEN` 只到秒）｜该件 `mtime` **`2026-09-28 18:13:34.951320315 +0800`**（亚秒）｜route 侧 `KNOWN-DEFECTS.md` `mtime` **`2026-09-28 18:13:34.743322461 +0800`** ⇒ **同秒同趟**（亚秒差 `0.208 s`，`DECL-GEN` 无亚秒字段 ⇒ 亚秒不可对它，我按 mtime 另给）。
- **三态（两遍现跑同值）**：`DEFREG=PASS declared=222 route_ids=222`（**两值相等**，全表 `③∧③′` 成立）＋ `DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN keys=-` ＋ `DEFREG_DECL=n=222 route_ids=222 grammar=D-[A-Z][0-9]*[a-z]?(-[A-Za-z0-9]+)*`。
- **新号同趟进两处**：`declared` 四行（`req=KD`／`present=KD`）＋ route 件 `KD` 四行，且两侧 `mtime` 同秒 ⇒ 规则④不红 ✓。

## §9 判词⑨ —— 未越域与红线：**成立（＋观察 `O4`）**

- **逐件现取**：`HANDOFF-NEXT.md` `b81567e26c29a527`＝＝`HEAD` 版逐位｜`verify-all.sh` `742175bffd5a175d`＝＝`HEAD`｜`build/close-wave.sh` `69c39feabe148c62`＝＝`HEAD`｜`docs/ROUTES.md` `26841d6ed6fe8085`＝＝`HEAD`｜`git diff HEAD -- src` **`0`** 行、`05148bb` 未碰 `src`（`0` 行）。
- **牙语义未改**：`build/MilBridge/tools/selfdescription-wiring-check.sh` 与 `05148bb^` 的 `git diff` **`0` 行**；`rule=forward-selfdesc-notwired-but-wired` ／ `rule=reverse-selfdesc-wired-but-not-wired` ／ `SD_NOTWIRED='未接线|不进 verify-all'` ／ `SD_WIRED='已接线'` 现取**各命中 `1`** ✓。
- **两枚哨兵**：`/tmp/bridge-frozen.flag` 与 `$HOME/wfp-runs/bridge-frozen.flag` 现取各 `sha16 6cb3f97388c3c4dc`／`13` 行／`279 B`／`mtime 13:48:27.398116209` ⇒ **`cmp IDENTICAL`** ✓。
- **`porcelain` 逐行点名**：见 §0（`3` 行，均非本笔）；`build/MilBridge/tools` 下未跟踪件 `0` ⇒ 仓内夹具残留 `0`。
- **观察 `O4`（不判 `t53` 红）**：`selfdescription-wiring-check.sh` 工作树模式 **`600`**（索引 `100644`）—— `05148bb` 只碰三件、该件与 `05148bb^` 内容差 `0` 行 ⇒ **非 `t53` 所动**；但 `600` 是本会话 `D-G187` 家族的**又一形态**（对 git 非「可执行位」位移 ⇒ `porcelain` 干净、任何内容类牙与 `bash -n` 都看不见）⇒ 建议归 `D-G187` 条目或另记。

## §10 判词⑩ —— 模式守恒自证（登记该族的这趟自己不得犯）：**成立**

- `t53` 动过的三件：`KNOWN-DEFECTS.md` 索引 `100644`／工作树 `644`｜`declared.tsv` 索引 `100644`／工作树 `644`｜`P1-dg184-report.md` 索引 `100644`／工作树 `644`；**写前**（`05148bb^`）`git ls-tree` 现取：前两件亦 `100644`，第三件由 `05148bb --summary` 现取 `create mode 100644` ⇒ **逐件两时点一致、零位移** ✓（`ts=2026-09-28T18:16:05.422519317+08:00`／`18:18:06.784802717+08:00`）。

---

## `NOINFO`（具名，既不算绿也不算红）

1. `NOINFO(reason=未跑「真跑」形态)`：`wave-push.sh` 我以 `--dry-run` 取 `stderr=0`（**真跑会写** `/tmp/bridge-frozen.flag` 与 `$HOME/wfp-runs/bridge-frozen.flag` 两枚哨兵 ⇒ 不得扰动）；「真跑 `stderr=0`」这句我未直接验（该自述行现取为 `#` 注释行、结构上不可能产生 `stderr`；`bash -n` `72/72` 全过为其旁证）。
2. `NOINFO(reason=未跑整趟门禁)`：`verify-all` 未跑（一跑即构建 ⇒ `provider` 位位移）。
3. `NOINFO(reason=修前世界为等价重建)`：§3／§5 的「修前」读数由 `git archive` 在**仓外**重建（非当时现场盘）；`t53` 当时的私有备份世界我不复现。
4. `NOINFO(reason=他车道在飞)`：`P1-task0201-criteria.md`（`t7`）／`P1-w4b-verify.md`（`t50`）／`P1-w4b-repair-verify.md`（`t54`）**不计入**本判词。
5. `NOINFO(reason=未审计别处同类面)`：我未全仓扫「行首无 `#` 自述」与**全部件**的文件模式（只扫 `build/MilBridge/tools/*.sh` 的 `bash -n` 与在册三件实例）⇒ `D-G186`／`D-G187` 两族在仓内是否还有别的实例，**未判**。

---

## 推翻的话 ＋ 结论

- **推翻 `t53` 的话**：**没有**。条目所报的关键机器值我逐条独立复现：`SELFDESC_ROSTER` 逐值（`72/50/22/51/3/18/0`）、反极点名件与 `rule=forward…`、修前 `undeclared=53／selfdesc_wired=12／wired=47`（我重建修前世界得同值）、三件修前原文与字样表零命中、修后 `stderr 0/0/0`、修前 `7/7/8` 行、两处 `mode change` 方向、`100755`／`755` 成对、台账 `2` 条 `A6 start=`／`CHAIN_ABORTED 0`／`chain.pid` 与活进程不一致、`DECL-GEN` 与两侧 `mtime` 同秒、两遍 `DEFREG=PASS declared=222 route_ids=222` ＋ `DECLDRIFT=0`、四件 `== HEAD`、两哨兵 `cmp IDENTICAL`、三件模式守恒。
- **结论**：必核条目 `1–10` **全部成立**；**三处 `low`**（`O1` 无独立「最小复现」段｜`O2` 现象行 `…` 省略与「逐条点名」自称不符｜`O5` 实为整件 `sha16` 被紧贴在「件头某行」之后｜`O6` 第 5 实例的 `218` 为未标口径的当时值 —— 共 4 条，均不改变成立）＋ **两处观察**（`O3` 两条无「反极」侧｜`O4` 牙件工作树 `600` 非本笔但属 `D-G187` 家族）。**`verdict = pass`**。


⏪ **dated 追加（落定后复取；`ts=`写作时刻（现取 `date`）＝ `2026-09-28T18:19:43.123251326+08:00`）**：① 本件 §0 的 `porcelain` 是**当时刻**读数（`3` 行）；**落定后复取已位移** —— `?? build/MilBridge/P1-w4b-repair-verify.md`（`t54` 车道）**已不在**未跟踪列表（该车道自行处置），现取未跟踪为 `?? build/MilBridge/P1-dg184-verify.md`（**本件**）／`?? build/MilBridge/P1-task0201-criteria.md`（`t7`）／`?? build/MilBridge/P1-w4b-verify.md`（`t50`）；**本判词所判的 `t53` 三件与越域四件同刻复取不变**（`HANDOFF-NEXT.md b81567e26c29a527`／`verify-all.sh 742175bffd5a175d`／`close-wave.sh 69c39feabe148c62`／`ROUTES.md 26841d6ed6fe8085`）。② **本席自伤如实（本件第 `1` 处，零损伤）**：本件由写作工具建出时模式为 `600`，落定前已 `chmod 644`（与本波报表件一致）；`sha16` 不受影响。③ 本件正文（§0–§10 与 `NOINFO`／结论）**一字未改、删行 `0`**。
P1-DG184-VERIFY: t56 attempt 2 | verdict=pass | 必核条目①-⑩全部成立｜推翻 none｜low 4（O1/O2/O5/O6）｜观察 2（O3/O4）| 被判三件 KD 58acad853a8dd7d5/3788/644 ｜ declared 850c185b2cf04aa9/232/644 ｜ report 0048c5ddf0e34804/19/644（末行自证 3c67b155c8b0977b）| HEAD 05148bb | 四号占用 05148bb^ 命中 0 ＋ 最大号 187 ＋ 四行 req=KD/present=KD ≡ 现场 KD(4)/CS(0)/HO(0)/AB(0) | D-G184 正极 ROSTER 72/50/22/51/3/18/0 PASS run_step=61；反极（我造，最小世界）rc=1 FILE wave-push.sh rule=forward-selfdesc-notwired-but-wired FAIL examined=1 fails=1；修前重建（git archive 3aaaa3e^）68/47/21/53/3/12/0 run_step=58 ⇒ 53→51/12→18/47→50 | D-G185 台账 177 行/唯一 164/重复 12 逐条（A6C W126..W136）/sha16 5aa5770a40e2fc58 @18:17:54.481858107（过程值非结账值）｜A6 start= 2｜CHAIN_ABORTED 0｜chain.pid 610180 DEAD vs 1717529 ALIVE | D-G186 修后 stderr 0/0/0 ＋ bash -n 72/72；反极 bash -n rc=0 ∧ 真跑 rc=3 stderr 2 行；修前（fcb5cd4^ 全树）7/7/8 行，裸行 :4/:5/:21；第5实例 缺省 NOINFO no-declaration → 注入全量 DRC_*（含 DRC_DECL） rc=0 PASS declared=222（条目引 218 为当时值） | D-G187 3aaaa3e 三行 100755=>100644 ／ fcb5cd4 三行 100644=>100755 ／ ls-files 100755 工作树 755 ／ 仓内无模式牙（tools 无 100755 引用，61 步中 MODE 0） | 同趟 DECL-GEN 18:13:34 vs declared mtime 18:13:34.951320315 vs KD mtime 18:13:34.743322461；两遍 DEFREG=PASS 222/222 ＋ DECLDRIFT=0 | 红线 HANDOFF b81567e26c29a527／verify-all 742175bffd5a175d／close-wave 69c39feabe148c62／ROUTES 26841d6ed6fe8085 全 ==HEAD、src diff 0；两哨兵 cmp IDENTICAL 6cb3f97388c3c4dc；porcelain 3 行均非本笔 | 模式守恒 三件 100644/644 写前同值 |

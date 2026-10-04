# W119A 报告 —— `TASK-0706`：把「**装置/口径卫生**」做成一件常态牙（新工具 ＋ 两极化自检 ＋ 接线草案）

- 车道：**W119A**｜日期：**2026-09-22 23:30 开工 → 2026-09-23 09:xx**（**宿主 00:07 挂起**，09-23 08:30 复跑，见 §7.1）
- 仓根 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（**本机 `R` 不是 git 仓库**；推送不在本件）
- 冻结基线 `#51 38e67e834430d75c`
- 纪律：**零 `dotnet`／零构建／零应用／不占槽／零 `pkill`**；**不接线**（只给逐字草案）
- 判据先写：`~/w119a/criteria.md`（**§7 是读数之后追加的加注**，含两处我必须自陈的偏离）
- 流水：`~/w119a/STATUS.md`（每完成一小步追加 —— 挂起证明了它的价值）
- **未碰**（其余车道写域）：`docs/ROUTES.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／
  `defect-registry-declared.tsv`（W120A 等正在改）／`verify-all.sh`／`close-wave.sh`／`integration-wave.sh`／
  任何**既有**牙／任何产品件（`src/**`、`build/shims/**`、`build/Presentation*.Linux/**`、applier）／冻结基线。
  **未跑** `verify-all.sh`／`close-wave.sh`／`integration-wave.sh`。

---

## §0 一句话结论

**新牙落在 `build/MilBridge/tools/hygiene-tooth.sh`**（`sha16 dc1e79a23dbb7eb2`／**1626 行**／96,559 B／
`bash -n rc=0`／`--selftest` **67/67 PASS**／单趟 **≈3–5 s**／**纯读**）。四类分项现场读数：

| 分项 | 读数 | 说明 |
|---|---|---|
| `HYGIENE_ROOTS` | **PASS** | 登记表内 1 对（WIC 同步器 × 校验器）：声明集合 == `--print-scan-roots` 集合；同步器无自写默认根 |
| `HYGIENE_EVIDENCE` | **PASS** | 仓内 72 件脚本体：**承重证据名文件的截断写 = 0**；另有 2 处同形但**不在引用面**的站点**逐条点名**（不判红） |
| `HYGIENE_INODE` | **🔴 FAIL** | **`build/MilBridge/known-red.json`（`nlink=3`）跨区同 inode × 登记写者 `repin-generation.py:112` 是原地写** ⇒ 写穿两个仓外夹具（见 §3.4，**这是本次最有价值的一条**） |
| `HYGIENE_SCOPE` | **REPORT**（**永不为 PASS**） | 10 格候选：3 格机械可判（`poison=no`，**有判别力**）、**7 格 `semantic_undecidable` 需人读** |
| `HYGIENE_TOOTH` | **FAIL** | 三态总行 = `FAIL roots=PASS evidence=PASS inode=FAIL scope=REPORT semantic_undecidable=7 multilink=1388 cross_region=1383`；**这个 FAIL 是设计内的正确读数**，不是牙坏了 |

> ⚠️ **注意读法**：牙的 `PASS` 从来不等于"全域干净"；总行**强制**带 `scope=`／`semantic_undecidable=`／
> `multilink=`／`cross_region=`／`ext_ext_hits=` 五格 ＋ 一条 `HYGIENE_BOUNDARY` 边界句（§3.5 逐字）。

---

## §1 判据（**先写**；逐字照抄 `~/w119a/criteria.md`，`sha16 80846a5cc9e484fc`）

### §1.0 三态与总行（写死）
- `HYGIENE_TOOTH=PASS|FAIL|NOINFO` ＋ `rc=0/1/2`；**`NOINFO` 既不算绿也不算红**（纪律 21/27/28）。
- 四个分项：`HYGIENE_ROOTS=`／`HYGIENE_EVIDENCE=`／`HYGIENE_INODE=`／`HYGIENE_SCOPE=`。
- 总行 = `FAIL`（任一分项 FAIL）> `NOINFO`（任一分项 NOINFO 且无 FAIL）> `PASS`。
- **`HYGIENE_SCOPE` 永不为 `PASS`**（只能 `REPORT`／`NOINFO`）⇒ **不许声称全域干净**。

### §1.1 第一类 `HYGIENE_ROOTS`（`D-G91` 的推广）
登记表 `A`：`(同步器, 校验器, 校验器默认根常量名, 只读派生旗标)`。逐对判五条：
`R1` 默认根常量**可静态抽出**（`$REPO`→`$ROOT` 展开成**集合 A**）⇒ 抽不出 `NOINFO`｜
`R2` 校验器 `--print-scan-roots` 吐出的**集合 B == A**（集合比较）⇒ 不等 `FAIL decl-vs-print-diverge`｜
`R3` 同步器**无自写默认根字面量**（`SCAN_ROOTS=` 赋值的 RHS 去掉 `$VAR` 引用后**不许含 `/` 或 `:`**）⇒ 命中 `FAIL self-written-default`｜
`R4` 同步器**含派生调用**（可执行行里有 `--print-scan-roots`）⇒ 缺 `FAIL derivation-missing`｜
`R5` 同步器**含收窄拒绝**且 `exit 2` 的行号**< 第一处汇总打印**的行号 ⇒ 缺 `FAIL narrow-guard-missing`／行序反 `FAIL narrow-guard-after-summary`。
**口径**：只对登记表里的对负责；登记表外的"两处各写一份"**未查**（打印）。

### §1.2 第二类 `HYGIENE_EVIDENCE`（`D-G96` 的推广）
形态（可执行行）：`: > T`／行首 `> T`／`true > T`／`truncate -s 0 T`（`>>` 是追加，用 `(?!>)` 排掉）。
**判红四条件合取**：①`FIXED`（跨趟固定：解析后不含 `$$`／`$(date`／`mktemp`／`<TMPDIR>`，且不再含未解出的 `$`）
∧ ②**证据名**（基名匹配 `(^|[^a-z])(log|logs|progress|evidence|trace|record|journal|dump|report|census|readings)([^a-z]|$)`）
∧ ③不在本件自己的 `--selftest` 区间 ∧ ④**承重**（见 `§7.2` 的加注）。
**不判红但必须可见**：`NOTCITED`（固定＋证据名但不在引用面）／`NOTNAME`／`NOTFIXED`／`SELFTEST`／`SELF`／`DOC` —— **逐类计数 ＋ 点名**。
**仓外登记装置根**（`$HOME/w63a/bin`）默认**只报不判**（仓外状态不是仓的性质）；`--strict-ext` 才进 `rc`。

### §1.3 第三类 `HYGIENE_SCOPE`（`D-G97`／`D-G42` 判别式）—— **审计报告**
机械找候选格：`VAR="$(<登记命令> …)"` ⇒ 后文对 `$VAR` 的**关键词文本测试**。逐格判：
**(a) 形状**（`glob`／`grep`／`nonempty`）｜**(b) 承载**（捕获行**无管道** ⇒ `bearing=yes`）｜
**(c) 中毒**：**语义的、机械不可判** ⇒ `poison=undecidable`（**不许机器猜**）；**唯一例外** = 命令在**失败文案登记表**里
（本件只登记**有现场证据**的一条：`xprop|stdout|_NET_SUPPORTING_WM_CHECK:  no such atom on any window.` = `D-G97` 逐字原文）。
`poison=yes ∧ bearing=yes` ⇒ **`FAIL`（被证明的恒真谓词）**；任何一格判不了 ⇒ 计 `semantic_undecidable` ⇒ `REPORT`。

### §1.4 第四类 `HYGIENE_INODE`（主控 09-23 追加；`W120A` 发现）
① 列出覆盖面内 `links>1` 的件；② 列出**跨区同 inode 对**（`$R` ↔ 登记的夹具根）；
③ **`FAIL`** = 跨区同 inode ∧ 该件的写者被**登记表 F 机械确认**为**原地写**；
只 `links>1` 无跨区 ⇒ **报告行**；`stat` 失败／夹具根全缺／写者形态抽不出 ⇒ **`NOINFO`**；
④ 孪生件**成对样板**：逐对打印两面 `sha16/nlink/inode` ＋ `same_inode` ＋ `anchor/exp_side`。

---

## §2 覆盖面声明（**逐类**；含「**没扫什么**」）

```
HYGIENE_SCOPE_DECL pairs=1 code_exts='.sh .bash' doc_exts='.md'
  evidence_name_re='(^|[^a-z])(log|logs|progress|evidence|trace|record|journal|dump|report|census|readings)([^a-z]|$)'
  skipdirs='.git obj bin .artifacts upstream node_modules __pycache__ .vs TestResults .dotnet'
  cmd_roster=8 failtext_entries=7 ext_roots=1 min_files=60 min_pairs=1 anchors=strict strict_ext=0
HYGIENE_SCOPE_PAIRS build/DirectWrite.Linux/wic-shim/sync-applocal-authority.sh|build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh|SCAN_ROOTS_DEFAULT|--print-scan-roots
HYGIENE_EVIDENCE_CITE surface_files=69 override=0 roots='build/MilBridge/arm-logs'
HYGIENE_INODE_ROSTER repo_files=1493 fixture_files=13132 multilink=1388 cross_region=1383 fixture_roots=2 missing=0
```

| 类 | 覆盖面（件数） | **没扫什么**（机器可见的边界） |
|---|---|---|
| ① 根集合 | **1 对**（WIC 同步器 × 校验器 ／ 登记表 A） | 登记表**外**的一切"两处各写一份根集合"**未查**（`HYGIENE_ROOTS_UNCHECKED`） |
| ② 证据保全 | **72 件脚本体**（`.sh`/`.bash`）＋ 281 件 `.md`（只计数）；判红层 0 命中、`not_cited=2`、`not_name=4`、`notfixed=57`、`selftest_region=14`、`self=5`、`doc=640` | `sed -i`／`tee`／`cp`／`mv`／`python open(w)` 等**其余写形态未解析**；仓外**未登记**的装置根未扫；`.md` **只计数不判红**；引用面 = 缺陷册 ＋ `docs/**/*.md`（**排掉** `build/MilBridge/*-report.md`，那是车道叙述不是引用） |
| ③ 口径射程 | **10 格**（8 个命令名 × 候选格）；`selftest_excluded=0`；`derived_predicate_sites=20` | **命令族外的命令未查**（登记 roster = `xprop xdpyinfo xwininfo xdotool xrandr wmctrl pgrep ps`）；**派生值上的文本测试未计入候选格**（被测串经 `sed`/`awk`/`printf` 二次处理 ⇒ `(b) 承载` 按定义不成立，但「是不是恒真」**仍未查**）；**未登记命令的 `(c)` 一律 `undecidable`**（人读） |
| ④ 硬链接 | 仓内 **1493 件**（`links>1` **1388 件**、跨区 **1383 件**）＋ 夹具 **13,132 件**（2 个登记根） | 其余原地写形态未机械解析；**只对登记表 F 里的写者负责**；**符号链接未跟随**；`$HOME` 里**未登记**的夹具区未扫 |

---

## §3 现场机读行（**四类分项 ＋ 总行 ＋ 边界句**）

### §3.1 第一类（PASS）逐字
```
HYGIENE_ROOTS_PAIR id=build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh state=PASS why=ok
  const=SCAN_ROOTS_DEFAULT flag=--print-scan-roots
  setA='/…/wpf-linux/build:/…/samples:/…/src:/…/tests:/…/tools'
  setB='/…/wpf-linux/build:/…/samples:/…/src:/…/tests:/…/tools'
  sums_at=111 guard_exit_at=71
HYGIENE_ROOTS=PASS pairs=1（登记表内每一对：声明集合 == 打印集合 == 同步器派生集合；无自写默认根）
HYGIENE_ROOTS_UNCHECKED pairs_declared=1 only-registered-pairs-are-checked（登记表外的「两处各写一份根集合」**未查**）
```
⇒ `setA`（静态抽出 `SCAN_ROOTS_DEFAULT` 并展开 `$REPO`）与 `setB`（`--print-scan-roots` **现跑**）**逐位相同**；
`guard_exit_at=71 < sums_at=111` ⇒ 收窄拒绝**发生在任何 `STALE=` 汇总之前**（`R5` 成立）。

### §3.2 第二类（PASS）逐字
```
HYGIENE_EVIDENCE_ROSTER code_files=72 doc_files=281 ext_files=8 rows=726 sites=722
HYGIENE_EVIDENCE_NOTJUDGED notfixed=57 not_name=4 not_cited=2 selftest_region=14 self=5 comment_or_doc=640 blinded=0
HYGIENE_EVIDENCE_NOTCITED site=build/MilBridge/tools/retake-arms-w21.sh:24 form=bare
  target='<HOME>/wfp-runs/arms21/build-coverage.log' raw='> "$OUT/build-coverage.log" 2>&1'
  （固定 ＋ 证据名，但**不在引用面**、也不在承重证据根下 ⇒ 按判据**不判红**，此处逐条点名）
HYGIENE_EVIDENCE_NOTCITED site=build/MilBridge/tools/retake-arms-w23.sh:111 form=bare
  target='<HOME>/wfp-runs/arms23/build-coverage.log' raw='> "$OUT/build-coverage.log" 2>&1'（同上）
HYGIENE_EVIDENCE=PASS code_files=72 exec_hits=0 not_cited=2（…对跨趟固定的**承重**证据名文件做截断写 = 0）
HYGIENE_EVIDENCE_EXT=CLEAN ext_files=8 other=2 not_cited=2 strict=0
HYGIENE_EVIDENCE_EXT_NOTCITED site=campaign.sh:52 form=colon target='<HOME>/w63a/logs/campaign.progress' raw=': > "$PROG"'
HYGIENE_EVIDENCE_EXT_NOTCITED site=control.sh:15 form=colon target='<HOME>/w63a/logs/control.progress' raw=': > "$PROG"'
```
⚠️ **并发披露**：本件跑读数期间**别的车道在写仓**（`build/MilBridge/W120A-report.md` 08:33、
`W115A-report.md` 08:36、`build/MilBridge/tools/uia-door-check.sh` 08:43、`ime-landing-check.sh` 08:46）
⇒ `code_files=72` 是**那一瞬间**的现算值（`.sh` 件数随时会变）；本件**不冻结**这个数，
它只用于"覆盖面不是零"的下限判据（`MIN_FILES=60`）。

**两条必须说清的话**：
1. **判红层 0 命中**不是"没看"：`wm.progress`／`wm198.progress`／`arm-logs/` 这些**承重**名在缺陷册里被引用
   （`wm.progress` **9 处**、`wm198.progress` **5 处**、`arm-logs/` **6 处**，机械核）⇒ 若 W113A 的修法被回退，
   本牙**会**红 —— 这条用 `--selftest` 的 `S02`（注入真形态 ⇒ 必红）＋ `S14`（血案形态 `under-evidence-root` ⇒ 必红）**成对证明**。
2. **仓外还活着 2 处 `D-G96` 同形实例**（`~/w63a/bin/control.sh:15`、`~/w63a/bin/campaign.sh:52`，都是
   `: > "$PROG"` 且 `PROG="$HOME/w63a/logs/*.progress"`）：它们**不在**引用面上（全仓 `grep` = 0 命中）⇒ 本牙**只报不判红**；
   但**如实点名**——**不许假装干净**。（W113A 只修了同一族里的 `wm-leg.sh`／`wm-leg198.sh` 两件。）

### §3.3 第三类（REPORT）逐字（10 格）
```
HYGIENE_SCOPE_CASE id=1  file=build/MilBridge/tools/t1c-census.sh line=251 cmd=xwininfo shape=nonempty bearing=no  poison=undecidable keywords='(none)'
HYGIENE_SCOPE_CASE id=2  file=build/MilBridge/tools/wm-awaited.sh line=84  cmd=xprop    shape=glob     bearing=yes sink=stdout poison=no keywords='= "'
HYGIENE_SCOPE_CASE id=3  file=build/MilBridge/tools/wm-awaited.sh line=110 cmd=xprop    shape=grep     bearing=yes sink=stdout poison=no keywords='='
HYGIENE_SCOPE_CASE id=4  file=build/MilBridge/tools/wm-awaited.sh line=111 cmd=xprop    shape=grep     bearing=yes sink=stdout poison=no keywords='='
HYGIENE_SCOPE_CASE id=5  file=build/MilBridge/tests/RGateClickProbe/run-r-gate-legs.sh line=172 cmd=xdotool shape=nonempty bearing=no poison=undecidable
HYGIENE_SCOPE_CASE id=6  file=build/MilBridge/tests/RGateClickProbe/run-r-gate-legs.sh line=175 cmd=xdotool shape=nonempty bearing=no poison=undecidable
HYGIENE_SCOPE_CASE id=7  file=build/MilBridge/tests/RGateClickProbe/run-r-gate-legs.sh line=297 cmd=xdotool shape=grep     bearing=no  poison=undecidable keywords='EVID popup id=,1'
HYGIENE_SCOPE_CASE id=8  file=tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe.sh line=413 cmd=xwininfo shape=nonempty bearing=no poison=undecidable
HYGIENE_SCOPE_CASE id=9  file=tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe.sh line=415 cmd=xwininfo shape=glob     bearing=no  poison=undecidable keywords='IsViewable'
HYGIENE_SCOPE_CASE id=10 file=tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh line=851 cmd=xwininfo shape=nonempty bearing=no poison=undecidable
HYGIENE_SCOPE_UNCHECKED derived_predicate_sites=20（…）; cmd_roster=xprop xdpyinfo xwininfo xdotool xrandr wmctrl pgrep ps 之外的命令族**未查**
HYGIENE_SCOPE=REPORT cases=10 decided=3 semantic_undecidable=7 poison_yes=0
```
**判别式是活的（不是永远 REPORT）**：`id=2/3/4` 三格是 `(a) ∧ (b)` 全中、`(c)` **被登记表**判成 `no`
（关键词 `= "`／`=` **不在** `xprop` 的已登记失败文案里）⇒ **这三格是"有判别力"的**，正是修复后的
`wm-awaited.sh` 该有的样子。**没有 `poison=yes`** ⇒ 今天**不存在**被证明的恒真谓词。
`S06` 用夹具**造**一格 `poison=yes` ⇒ `HYGIENE_SCOPE=FAIL` ＋ `HYGIENE_SCOPE_POISON` 逐条点名（**判别式真会开火**）。

### §3.4 第四类（**FAIL**）逐字 —— 本次最要紧的一条
```
HYGIENE_INODE_ROSTER repo_files=1493 fixture_files=13132 multilink=1388 cross_region=1383 fixture_roots=2 missing=0
HYGIENE_INODE_WRITERS build/MilBridge/known-red.json|build/MilBridge/tools/repin-generation.py|inplace|inplace-literal:open(REG, "w"
HYGIENE_INODE_TWIN file=docs/PORT-SPEC.md fixture=/home/links-dev/w62a/negrepo/docs/PORT-SPEC.md same_inode=no
  repo_sha=8a276090e3e6180f fix_sha=7f36186d68a18332 exp=7f36186d68a18332 anchor=ok exp_side=fix src=W120A
  repo_nl=1 repo_ino=4852681 fix_nl=1 fix_ino=5000462
HYGIENE_INODE_TWIN file=docs/INDEX.md … same_inode=no repo_sha=6ff758d05778f5cf fix_sha=c36ed5fe2a5904a7 exp=c36ed5fe2a5904a7 anchor=ok exp_side=fix
  repo_nl=1 repo_ino=4852682 fix_nl=1 fix_ino=5000466
HYGIENE_INODE_TWIN file=build/MilBridge/tools/defect-registry-declared.tsv … same_inode=no
  repo_sha=dea8c731369ba0ed fix_sha=934a29ed9ab399ab exp=934a29ed9ab399ab anchor=ok exp_side=fix
  repo_nl=1 repo_ino=5383439 fix_nl=1 fix_ino=4932707
HYGIENE_INODE_TWIN file=build/MilBridge/known-red.json fixture=/home/links-dev/w62a/negrepo/build/MilBridge/known-red.json
  same_inode=yes repo_sha=089b7324ba12e022 fix_sha=089b7324ba12e022 exp=089b7324ba12e022 anchor=ok exp_side=both src=W119A现算
  repo_nl=3 repo_ino=5251064 fix_nl=3 fix_ino=5251064
HYGIENE_INODE_FAIL file=build/MilBridge/known-red.json writer=build/MilBridge/tools/repin-generation.py
  form=inplace cross=yes why=inplace-literal:open(REG, "w"（**原地写 × 跨区同 inode ⇒ 写穿夹具**）
HYGIENE_INODE=FAIL multilink=1388 cross_region=1383
HYGIENE_INODE_UNCHECKED sed -i／tee／cp／mv／python open(w) 等**其余原地写形态未机械解析**（只按登记表 F 的原地写字面量判）；符号链接未跟随；$HOME 里未登记的夹具区未扫
```

**三条读数各有各的意思（逐条给，不许混）**：
1. **🔴 活的风险（点名 1 件）**：`build/MilBridge/known-red.json` `nlink=3`，三个链接点分别是
   `$R/build/MilBridge/known-red.json`｜`~/w62a/negrepo/build/MilBridge/known-red.json`｜
   `~/w113a/fixture/fp-farm/build/MilBridge/known-red.json`（⇒ `n_fixtures=2`，**两个不同车道的夹具**）。
   而写者 `build/MilBridge/tools/repin-generation.py:112` **逐字**是
   `json.dump(d, open(REG, "w", encoding="utf-8"), ensure_ascii=False, indent=2)`
   ⇒ **`open(…,"w")` 截断的是同一个 inode**（不是 temp＋rename）⇒ **下一次 `repin-generation.py` 会当场改掉
   W62A 的负控仓与 W113A 的 `fp-farm` 里的那份 `known-red.json`**。这正是本条要抓的"**写坏别人的**"。
   ⚠️ 本牙**不修**（解链/改写盘是那些件写者的活，且 `~/` 下夹具是别的车道写域）—— **只点名**。
2. **`links>1` 是常态、不是异常**：`multilink=1388`（仓内 1493 件里 **93%**）。其中 **1383 件**同时在
   `~/w62a/negrepo/**` 下有同 inode 孪生件 —— 也就是说 **W62A 的"负控仓"基本是 `$R` 的硬链接农场**。
   按判据（未登记为原地写的）**只报不判红**，但**逐条上屏**（`HYGIENE_INODE_CROSS`／`HYGIENE_INODE_MULTILINK`，
   各截前 40 条 ＋ `_TRUNCATED printed=40 rest=1348`）。点名举例（**只读引用**）：
   `build/MilBridge/tools/pc-line-step.sh`（**一颗牙**）｜`build/MilBridge/tools/frame-step.sh`（**另一颗牙**）｜
   `wpf-linux.sln`｜`build/artifact-src-fp.py`／`.sh`｜`build/fonts/SHA256SUMS`｜`build/MilBridge/known-red.json.bak-20260917-151210`。
3. **主控给的三个孪生锚 = 夹具侧**，且**这三对已经解链**：`exp_side=fix` 说明 `7f36186d68a18332`／
   `c36ed5fe2a5904a7`／`934a29ed9ab399ab` 是**夹具侧**的 sha16，**与 W120A 现场一致**；
   但**仓侧的 inode 已经变了**（`4852681/4852682/5383439` ≠ 夹具侧的 `5000462/5000466/4932707`）
   且两侧内容已分叉（仓侧 `8a276090…`／`6ff758d0…`／`dea8c731…`）⇒ **这三对在挂起期间被 rename 型重写解链了**
   （⇒ `same_inode=no`）。**只有 `known-red.json` 仍是 3 链接同 inode**。
   ⇒ 成对样板照样给全（`repo_nl/repo_ino/fix_nl/fix_ino` ＋ 两面 sha16），**开工/收工各跑一次比对即可复算**。

### §3.5 总行 ＋ 边界句（逐字）
```
HYGIENE_TOOTH=FAIL roots=PASS evidence=PASS inode=FAIL scope=REPORT semantic_undecidable=7
  multilink=1388 cross_region=1383 ext_ext_hits=0 ext_strict=0 code_files=72
HYGIENE_BOUNDARY 本行的 PASS **只**等于：登记表内根集合对（1 对）机械可判部分一致
  ∧ 仓内判red 覆盖面（72 件脚本体）里截断写跨趟固定证据名文件 = 0。**不**等于全域干净：
  口径射程恒为 REPORT（semantic_undecidable=7 格需人读）、仓外装置根默认只报（ext_hits=0）、
  登记表外的根集合对与未登记命令族**未查**、文档体（.md）只计数不判红；
  第四类只判**登记表 F 确认的原地写者** × 跨区同 inode（1383 件跨区／1388 件 links>1），
  sed -i／tee／cp／mv／python open(w) 等**其余原地写形态未解析**，$HOME 里未登记的夹具区未扫。
HYGIENE_SELF path=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux/build/MilBridge/tools/hygiene-tooth.sh sha16=dc1e79a23dbb7eb2
```

---

## §4 `--selftest` 逐例读数（**67/67 PASS**，`rc=0`，16.5 s，自带 `TMPDIR`）

`ST_ATTEST=OPEN … sha16=dc1e79a23dbb7eb2` → `ST_ATTEST=PASS …（自测期间本件未变 ⇒ 读数可归因）`；
`HYGIENE_SELFTEST_ROSTER sandbox=/tmp/hyg-selftest.XXXXXX cases=67 pass=67 fail=0 not-as-expected=0`。

```
SELFTEST CASE S01a-self-written-default = PASS rc=1 want=1 tooth=FAIL   roots=FAIL   evidence=PASS scope=REPORT
SELFTEST CASE S01b-restore-derivation   = PASS rc=0 want=0 tooth=PASS   roots=PASS   evidence=PASS scope=REPORT
SELFTEST CASE S02-truncating-evidence   = PASS rc=1 want=1 tooth=FAIL   roots=PASS   evidence=FAIL scope=REPORT
SELFTEST CASE S03-append-and-unique-name= PASS rc=0 want=0 tooth=PASS   roots=PASS   evidence=PASS scope=REPORT
SELFTEST CASE S04a-empty-roster         = PASS rc=2 want=2 tooth=NOINFO roots=PASS   evidence=NOINFO scope=REPORT
SELFTEST CASE S04b-python-missing       = PASS rc=2 want=2 tooth=NOINFO roots=NOINFO evidence=NOINFO scope=NOINFO
SELFTEST CASE S04c-registry-unreadable  = PASS rc=2 want=2 tooth=NOINFO roots=NOINFO evidence=PASS scope=REPORT
SELFTEST CASE S05-scope-undecidable     = PASS rc=0 want=0 tooth=PASS   roots=PASS   evidence=PASS scope=REPORT
SELFTEST CASE S06-scope-poison          = PASS rc=1 want=1 tooth=FAIL   roots=PASS   evidence=PASS scope=FAIL
SELFTEST CASE S07a-ext-report-only      = PASS rc=0 want=0 tooth=PASS   roots=PASS   evidence=PASS scope=REPORT
SELFTEST CASE S07b-ext-strict           = PASS rc=1 want=1 tooth=FAIL   roots=PASS   evidence=PASS scope=REPORT
SELFTEST CASE S08-blinded               = PASS rc=2 want=2 tooth=NOINFO roots=PASS   evidence=NOINFO scope=REPORT
SELFTEST CASE S08b-same-tree-unblinded  = PASS rc=1 want=1 tooth=FAIL   roots=PASS   evidence=FAIL scope=REPORT
SELFTEST CASE S09-tmp-isolated          = PASS rc=0 want=0 tooth=PASS   roots=PASS   evidence=PASS scope=REPORT
SELFTEST CASE S12-cite-override-strict  = PASS rc=2 want=2 tooth=NOINFO roots=NOINFO evidence=NOINFO scope=NOINFO
SELFTEST CASE S13-notcited-visible      = PASS rc=0 want=0 tooth=PASS   roots=PASS   evidence=PASS scope=REPORT
SELFTEST CASE S14-evidence-root         = PASS rc=1 want=1 tooth=FAIL   roots=PASS   evidence=FAIL scope=REPORT
SELFTEST CASE S15-fixture-all-clean     = PASS rc=0 want=0 tooth=PASS   roots=PASS   evidence=PASS scope=REPORT
SELFTEST CASE S16a-inplace-cross-link   = PASS rc=1 want=1 tooth=FAIL   roots=PASS   evidence=PASS scope=REPORT
SELFTEST CASE S16b-temp-rename          = PASS rc=0 want=0 tooth=PASS   roots=PASS   evidence=PASS scope=REPORT
SELFTEST CASE S16c-writer-form-unconfirmed = PASS rc=2 want=2 tooth=NOINFO roots=PASS evidence=PASS scope=REPORT
SELFTEST CASE S17-fixture-roots-missing = PASS rc=2 want=2 tooth=NOINFO roots=PASS   evidence=PASS scope=REPORT
SELFTEST CASE S18-fixture-roots-override-strict = PASS rc=2 want=2 tooth=NOINFO roots=NOINFO evidence=NOINFO scope=NOINFO
（另有 44 条 SELFTEST ASSERT，全 PASS）
```

**「该 `NOINFO` 的有没有冒绿」—— 逐条交代（6 例全部落在 `NOINFO`/`REPORT`，无一条冒绿）**：

| 例 | 夹具 | 期望 | 实测 |
|---|---|---|---|
| `S04a` | 覆盖面低于下限（`MIN_FILES=999999`） | `NOINFO too-few-files` | ✅ `rc=2`，`evidence=NOINFO` |
| `S04b` | 缺 `python3`（`HYG_PYTHON=/nonexistent`） | `NOINFO python-missing` | ✅ `rc=2`，三项全 `NOINFO` |
| `S04c` | 登记表读不到（`HYG_PAIRS_FILE=/nonexistent`） | `NOINFO registry-unreadable` | ✅ `rc=2` |
| `S08` | **故意弄瞎扫描器**（同一棵树不弄瞎时**会红**） | `NOINFO scanner-blinded` | ✅ `rc=2`、`evidence=NOINFO`（**不冒绿也不冒红**）；`S08b` 同一棵不弄瞎 ⇒ `FAIL`（成对） |
| `S12` | **注入引用面 ＋ `ANCHORS=strict`**（把 `D-G91` 的教训用在本件自己身上） | `NOINFO narrowed-citation-surface` | ✅ `rc=2` |
| `S17` | 登记的夹具根**一个都不在** | `NOINFO fixture-roots-missing` | ✅ `rc=2` |
| `S16c` | 写者写盘形态**两种字面量都抽不出** | `NOINFO writer-form-unconfirmed` | ✅ `rc=2`（**不许猜**） |
| `S05` | `(c)` 故意不可判的一格 | `HYGIENE_SCOPE=REPORT`（**永不为 PASS**） | ✅ 断言「`HYGIENE_SCOPE` 不是 `PASS`」＋ 总行带 `scope=REPORT` |

**两极化成对（每组都是"注入 ⇒ 红、还原 ⇒ 绿"）**：`S01a/S01b`（自写默认根）｜`S02/S03`（截断写 vs 追加＋独立名）｜
`S08/S08b`（弄瞎 vs 不弄瞎）｜`S13/S14`（未被引用 vs 承重证据根）｜`S16a/S16b`（原地写 vs temp＋rename，
**且 `S16b` 仍打印 `HYGIENE_INODE_MULTILINK`** ⇒ 证的是"原地写"不是"看见 `links>1` 就红"）｜
`S07a/S07b`（仓外默认只报 vs `--strict-ext` 进 rc）｜`S06`（`poison=yes` ⇒ SCOPE 必红）。

**自测的两条纪律动作**：① 沙箱落在**本牙给的** `TMPDIR` 之下（`S09` 断言 `HYGIENE_TMPDIR=$SB/tmp/`）；
② 共享 `/tmp` 上 `hyg-run.*` 残留 = **0**（`S10`）。⚠️ 本牙**自己不写任何共享件**：全部输出走 stdout，
仅有的落盘是 `mktemp -d` 私有临时目录里的 TSV（**不覆盖任何既有名字**）。

---

## §5 接线草案（**逐字，不落地**）

> ⚠️ **本件不接进 `verify-all.sh`**（加步会打破冻结的 `27 gen=#51`）。以下四段是给主控的**逐字草案**，
> 锚一律用**正文字符串**（不给行号 —— 行号是活文档里最先烂的东西）。

### §5.1 `verify-all.sh` 四处同趟改（**缺任一处，第 `[11]` 步会正确地红**）

**① `DECL` 块最上面插一行**（锚 = 现第一行 `# VERIFYALL-STEPS-DECL: 27 gen=#51` 的**行首**，插在它**之前**）：
```
# VERIFYALL-STEPS-DECL: 28 gen=#52   ← `#52` **加一步**（27 → 28）：第 `[28]` 步 `HYGIENE` —— `TASK-0706` 的牙 `build/MilBridge/tools/hygiene-tooth.sh`：四类**装置/口径卫生**（① `D-G91` 根集合一致性 ② `D-G96` 证据保全 ③ `D-G97`/`D-G42` 口径射程**审计报告** ④ `W120A` **跨区同 inode**）。三态 `HYGIENE_TOOTH=PASS|FAIL|NOINFO`；**纯读、零 `dotnet`、≈3–5 s**；`HYGIENE_SCOPE` **永不为 PASS**（`REPORT`／`NOINFO`）⇒ 它**不**声称全域干净，边界逐字印在 `HYGIENE_BOUNDARY` 行上。（**步数：27 → 28**）
```

**② 头注释口径句**：在**最后一条**「**`#NN` 收官起 = N 步**」口径句**之后**追加半句（`verify-all-step-check.sh`
用 `grep -qF` 找这半句，**必须逐字**）：
```
｜**`#52` 收官起 = 28 步**（`#52` 加第 `[28]` 步 `HYGIENE`）
```

**③ `STEP-NAMES` 第一行末追加**（锚 = 该行**结尾的** ` | NUL-BYTES`，改成 ` | NUL-BYTES | HYGIENE`）：
```
# VERIFYALL-STEP-NAMES: 主工程 WpfGfx.Linux | … | R-GATE（连续交互） | NUL-BYTES | HYGIENE
```
（⚠️ `HYGIENE` 必须与 `run_step "HYGIENE"` 的**步名字面量逐字相同**。）

**④ 步本体**：插在**第 `[27]` 步 `NUL-BYTES` 之后、波尾汇总 `echo "======"` 之前**
（锚 = 逐字 `run_step "NUL-BYTES" bash build/MilBridge/tools/nul-bytes-check.sh` 那一行）：
```bash
echo
echo "[28] 装置/口径卫生：根集合一致性 ＋ 证据保全 ＋ 口径射程 ＋ 跨区同 inode（TASK-0706 的牙；只读、零 dotnet、≈3–5 s；#52 加）"
echo "     本步的绿 = ①登记表内根集合对一致 ∧ ②仓内判red 覆盖面里「截断写承重证据名文件」=0 ∧ ③跨区同 inode 的件里没有原地写者；"
echo "     ⚠️ 边界：口径射程恒为 REPORT（semantic_undecidable 那几格需人读）、仓外装置根默认只报、其余原地写形态未解析 —— 逐字见 HYGIENE_BOUNDARY 行"
run_step "HYGIENE" bash build/MilBridge/tools/hygiene-tooth.sh
```

### §5.2 ⚠️ 接线前**必须先裁决**的一件事（否则第 `[28]` 步必红）
本牙现场读数是 **`HYGIENE_TOOTH=FAIL`**，红在**第四类**：`build/MilBridge/known-red.json`（`nlink=3`）
× `repin-generation.py` 的**原地写**（§3.4 第 1 条）。**三种处置，选一**（都由主控裁定，本件不动手）：
- **(a) 解链**：把那份 `known-red.json` 从 `~/w62a/negrepo/**` 与 `~/w113a/fixture/fp-farm/**` 上解下来
  （`cp` 成独立件 ＋ `rm` 掉硬链接）⇒ 之后 `cross_region` 少 1 件、本类回 `PASS`。
  —— 代价：那两个夹具若**靠共享 inode 才等于真树**，解链后它们就是**快照**（W62A/W113A 需知情）。
- **(b) 改写者**：`repin-generation.py` 改成 **temp ＋ `os.replace`**（`D-G96` 的修法同型）⇒ 也回 `PASS`，
  且**同时**解掉"写穿"风险。**代价**：`known-red.json` 的 inode 会变（`ARM-LOG-SHA` 那族**不看 inode**，应无影响；
  但 `known-red.json` 在 `fp_inputs()` 名单里 ⇒ **`inputs_fp` 会变**，必须安排在 `IN_FP_0` 之前）。
- **(c) 先接线但接受红**：把它当"**已知活缺陷**"接线（与本仓 `COLUMN-FLOOR` 那类声明类红同族处理）。
  —— 本件**不建议**：`verify-all` 的 `✅/❌` 语义是"红=要么修要么登记"，**未登记的常态红会把门禁变噪音**。

### §5.3 接线同时要做的两件（仓内惯例，**判据件改了自己得有人看着**）
1. **把本件加进 `build/close-wave.sh` 的 `fp_inputs()` 显式 `printf` 名单**（`§6` 机械核：现在 **0 命中**）
   ⇒ **会动 `inputs_fp`** ⇒ **必须安排在 `IN_FP_0` 采样之前**（独立准备趟）。
2. `verify-all-step-check.sh` 会同一趟核对四处声明（`decl/count/prose/names`）⇒ 改完**先单独跑**
   `bash build/MilBridge/tools/verify-all-step-check.sh` 确认 `VERIFYALL_SELF=PASS`，**别整跑 `verify-all`**。

---

## §6 `inputs_fp` 影响（**机械核**，不是估计）

| 机械核项 | 命令 | 读数 |
|---|---|---|
| 本件在不在 `fp_inputs()` 名单里 | `grep -c 'hygiene-tooth' build/close-wave.sh` | **0** ⇒ **新建本件不动 `inputs_fp`** |
| 本件在不在 `find` 覆盖面里 | 名单是**显式 `printf` 列举**（15 个续行），本件不在其中 | 同上，**0 命中** |
| 报告在不在覆盖面 | `*.md` 不在任何 `find` 分支里（`patch-*.py`／`port-lib.py`／`*.sh`／`*.cs`／`*.c`／`*.h`） | **不在** |
| `fp_inputs()` **现值**（唯一真源，`source` 真函数现算） | `source <(sed -n '/^fp_inputs()/,/^}/p' build/close-wave.sh); fp_inputs` | **`72c5f2263f62a83d301f0852edcb049825e51be09e5646cad55274ba91e48015`** |
| 覆盖面内**被别的车道改过**的件（**如实点名，不是异常**） | — | `src/WpfGfx.Linux.Native/src/win32_core.c` `3117923a7c899e05`｜`win32_x11.c` `11142fbef049eb66`（`find src/WpfGfx.Linux.Native -type f \( -name '*.c' -o -name '*.h' \)` 在覆盖面内）＋ W113A 的 4 件（`check-applocal-sync.sh`／`sync-applocal-authority.sh`／`run-wpftextdemo.sh`／`frame-presence-check.sh`／`run-wpfprobe.sh`／`pipefail-sigpipe-check.sh` 中的 4 件在名单里） |
| 接线的流程代价 | `close-wave.sh` 的 `IN_FP_0` 在 `[0/6]` 之后、`IN_FP_1` 在 `[4/6]` | **"改判据件必须排在 `IN_FP_0` 之前"** ⇒ §5.3-1 必须照办 |

⇒ **一句话**：**今天新建本件 ＝ `inputs_fp` 不动**；**接线时把它加进名单 ⇒ `inputs_fp` 必动**
（设计性变更），**必须排在 `IN_FP_0` 采样之前**。

---

## §7 `NOINFO`／未做／纪律偏离（**如实列，宁可标"未取到"**）

### §7.1 宿主挂起（本车道的现场事实）
- 我在 **2026-09-22 23:30–00:05** 写完牙的骨架并正在调自测时**宿主 00:07 挂起**；`~/w119a/STATUS.md` 只留下 `[T0]`。
  09-23 08:30 主控叫醒后我**从头复核现场**（§7.2 的锚全部**现算**）再续跑。
- **自纠（写域偏离）**：`criteria.md` 最初被我写到 **`$HOME` 之外**的
  `/home/links-dev/netTest/wpf-linux-20260906/w119a/`（`$R` 的**兄弟目录**）⇒ 已 `cp -p` 搬回 `~/w119a/`
  并**删掉那个仓外目录**。**仓内零影响**（它在仓外），但**如实登记为纪律偏离**。
- **纪律偏离（判据先写）**：第四类的判据是**动手前**先写进牙的头部注释与登记表 `F/G/H` 的，
  但**没有同步抄进 `criteria.md`** —— `criteria.md §7` 是**落地之后**补的（§7 已逐字自陈）。

### §7.2 复跑时的锚复核（**现算**；挂起期间有别的车道改过件）
```
fe3e3fde0f456250  docs/ROUTES.md            ← W120A 在改（我只读）
d85d0de47acb550c  samples/WpfFeatureProbe/KNOWN-DEFECTS.md   ← 同上（我只读）
dea8c731369ba0ed  build/MilBridge/tools/defect-registry-declared.tsv  ← 同上（我只读）
153a997ae6bc68b9  build/MilBridge/W113A-report.md            ← 与昨夜一致
ea854808dfe3450a  build/DirectWrite.Linux/wic-shim/sync-applocal-authority.sh   ← 一致
346dc4e0bf6724e8  build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh      ← 一致
1aa2ae4e94827cf3  verify-all.sh ｜ c757fd5058f1bfd4  build/close-wave.sh ｜ 38e67e834430d75c  基线
```

### §7.3 **未做／`NOINFO`（逐条）**
1. **接线 = 未做**（本件只给草案）⇒ 第 `[28]` 步的 `HYGIENE_*` 在门禁里**还没有读数**；§5.2 的裁决**未做**。
2. **第四类的完整机械射程 = 部分未做**：只对**登记表 F 确认的原地写者**判红；
   `sed -i`／`tee`／`cp`／`mv`／`python open(w)`／`printf > 件` 等**其余原地写形态未机械解析** ⇒ 若某件用这些形态
   写穿夹具，**本牙今天看不见**（`HYGIENE_INODE_UNCHECKED` 行明写）。**`NOINFO`**。
3. **`$HOME` 里未登记的夹具区未扫**：`cross_region` 只对登记的 2 个根负责；`/home/links-dev` 下**还有别的**夹具区
   （本件只证明了"未扫"，**未**枚举完）⇒ `NOINFO`。
4. **第三类的 `(c)` 有 7 格需人读**（`semantic_undecidable=7`）—— 这是**设计**，不是缺陷；
   但"这 7 格到底有没有恒真"**本件没有答案**。**`NOINFO`**。
5. **符号链接未跟随**（`lstat` 语义）：如果某件用**软链**共享，本牙看不见。**`NOINFO`**。
6. **仓外 2 处 `D-G96` 同形实例**（`~/w63a/bin/control.sh:15`／`campaign.sh:52`）**只报未判红**，
   也**未修**（仓外 + 别的车道/主控写域）。
7. **`verify-all.sh` 端到端 = 未跑**（本件不跑构建/门禁）⇒ "第 `[28]` 步在真门禁里长什么样"**未取到**。
8. **`S10`（`/tmp` 无 `hyg-run.*` 残留）**一开始**红过一次** —— 那是**我自己**调试时用 `--debug-tmp` 留下的
   两个 `/tmp/hyg-run.*`（已清）；**清后 PASS**。如实记为"装置自伤、已修复"，不是牙的缺陷。

### §7.4 实现期抓到的**自己的**三处缺陷（详见 `~/w119a/criteria.md §7.3`）
1. **赋值右侧引号没剥** ⇒ `base` 变 `x.log"` ⇒ 引用面比对**恒定失配**（假阴性）—— 被 `S02` 的
   "判词必须写 `cited-basename`"断言当场抓到。
2. **解析器指数膨胀**：`"${OUT:-${R_GATE_OUT:-/tmp/r-gate-$(date …)-$$}}"` 让一条 `SITE` 行被撑到
   **72,394 字符**（现场实测）⇒ 改成**单趟扫描 ＋ `seen` 去环 ＋ 4 KiB 体积守卫**。
3. **本件自己踩了 `D-G42` 族陷阱**（双引号里的反引号）**两次** —— **两次都是仓内既有牙
   `shell-quote-trap-check.sh` 当场抓到的**（先 `traps=10`、改后再 `traps=10`），修后
   `SHELL_QUOTE_TRAP=PASS traps=0 files=156 sh=71 py=85 diag=71 allow=0`。
   ⇒ 这条**不是我"记得"**，是**别人的牙**给的可复算读数。

### §7.5 成对读数：本牙**零写入**（可复算）
```
FP（13,132 件夹具 ＋ 仓内全部非 obj/bin/.artifacts/upstream 件的 `路径|大小|mtime|inode` 聚合 sha16）
  FP_before=55d8e57e827f50a9
  FP_after =55d8e57e827f50a9     ⇒ READONLY_PROOF=IDENTICAL
（跑法：`bash build/MilBridge/tools/hygiene-tooth.sh` 夹在两次 FP 之间；本件只 `open('rb')` ＋ `os.stat`）
```
＋ 仓内同行牙的读数（**只读引用**）：`NULBYTES=PASS files=1201 hits=0 bytes=251446070 canary=ok`。

---

## §8 大白话小结（≤6 行）

1. **牙落好了**：`build/MilBridge/tools/hygiene-tooth.sh`（`dc1e79a23dbb7eb2`／1626 行／纯读／3–5 s／自测 67/67）。
2. **它当场抓出一条真危险**：`known-red.json` 与 `~/w62a/negrepo`／`~/w113a/fixture/fp-farm` **同 inode（3 链接）**，
   而 `repin-generation.py` 是**原地写** ⇒ **下一次重钉会写坏两个车道的夹具**（要主控裁决怎么处置：解链／改写者／接受红）。
3. **它还量出一件没人报过的事**：仓内 **1383 件**与 `~/w62a/negrepo/**` 硬链接同 inode（**含两颗牙** `pc-line-step.sh`／`frame-step.sh`）
   —— 今天按判据**只报不判红**，但**逐条上屏**。
4. **前两类现场 `PASS`**（根集合一致；承重证据名文件的截断写 = 0），**第三类恒为 `REPORT`**
   （10 格：3 格机械判"有判别力"、7 格**需人读**，`poison_yes=0`）—— **它从不声称全域干净**。
5. **接线草案四段逐字给全**（`DECL 28 gen=#52`／口径句半句／`STEP-NAMES` 末位 `| HYGIENE`／步本体）；
   **新建本件 `inputs_fp` 不动**（机械核 0 命中），**接线时要加进 `printf` 名单 ⇒ `inputs_fp` 必动 ⇒ 排在 `IN_FP_0` 之前**。
6. **我没做的**：接线、§5.2 的裁决、`sed -i` 等其余原地写形态的解析、仓外 2 处同形实例的修、`verify-all` 端到端。

---
（本报告 `sha256sum | cut -c1-16` 见收尾消息；本件**不含任何手抄哈希** —— 全文 sha16 均现场现算。）

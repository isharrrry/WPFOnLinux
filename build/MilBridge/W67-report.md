# `W67` 落仓报告 —— `TASK-0721`：把 `D-G122` 的牙 `PTS-PAGES` 接进 `verify-all` 第 `[38]` 步（**落地前预置**形态）

> 车道 **W160A-W67ARM**（本波 **唯一 owner**）｜工作目录 `~/w160a/`
> 权威树 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（**本波按放行件授权写入**）
> 放行件：`~/w129a/dispatch-W67-landing.md`（`556faa5c67b1d837`）｜判据先行：`~/w160a/criteria.md`（`157d595fb78fad4c`）
> 报告时刻：2026-09-25T10:10:50

---

## §1 本波做了什么（逐条 ＋ 现算读数）

### 1.1 落仓件（写前逐件 `cp -a --remove-destination` ＋ **`stat -c %h == 1` 断言**；先 `cp -p` 备份）

| 件 | before | after | 字节 |
|---|---|---|---|
| `verify-all.sh` | `f31123fac6e2c1e6` | **`9d28301987351fd1`** | 135,873 |
| `build/close-wave.sh` | `3f190c323b543275` | **`7281832adf70a02d`** | 41,078 |
| `docs/WAVE67-PREREGISTRATION.md` | —（新建） | **`b7da932a7dbcb934`** | 10,818 |
| `build/MilBridge/tools/pts-pages-guard.sh` | —（新建） | **`d42e9395f31e3681`** | 14,220 |
| `build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh` | —（新建） | **`b4b70bc0bf21074d`** | 10,683 |
| `…/session_inner.sh` | —（新建） | **`5ef538137c6700aa`** | 7,037 |
| `…/navclick.py` | —（新建） | `e3d8b6ec4f5a4f6a` | 8,933 |
| `…/legs-to-env.py` | —（新建） | `40105fec0b66d055` | 9,919 |
| `…/shotstat.py` | —（新建） | `65dea80e885c9f37` | 790 |
| `build/MilBridge/tests/PtsPagesProbe/evidence/**` | —（新建） | **16 件 / 660 KB**（本波**跑腿产出**） | — |

**判据件逐字节复核对拍**：`cmp build/MilBridge/tools/pts-pages-guard.sh ~/w156a/w67guard/bin/pts-pages-guard.sh` ⇒ **逐字节相同** ✅（即 W156A 在真腿 A/B/C 上验过的那份字节，**零改写**）。

**纪律 34（抄了别车道的装置必须断言"无外来硬编码路径"）**：六件上 `grep -cE '\$HOME/w1[0-9]+a'` = **0**（`FOREIGN_TOTAL=0`）；参数化 3 处（`ARMDIR`／`APPDIR`／`W=`）＋ `BIN` 改为**装置自身目录**。

### 1.2 四处声明（同趟）

`# VERIFYALL-STEPS-DECL: 38 gen=#67`（**插在现行第一行 DECL 之前** —— `decl_line()` 是 `sed … | head -1`，见 §5 ①）＋ 头注释口径句 ``**`#67` 收官起 = 38 步**`` ＋ `VERIFYALL-STEP-NAMES` 行尾 `| PTS-PAGES` ＋ 预登记 H1。**步数 37 → 38**。

### 1.3 整波 ＋ 门禁 ×2 ＋ 冻前（槽内严格串行）

| 环节 | 读数 |
|---|---|
| 整波 `close-wave.sh --skip-verify-all` | `rc=0`，`held=187s`，`native_rebuilt=0`／`bridge_republished=0` |
| 门禁 ×2（应用级，`:233`） | `WPTD_GATE=PASS acceptance=2/2`（两趟）｜`GATE_LINES_IDENTICAL=yes`｜两趟各 **6 条 `BASELINE … result=PASS`** ｜`WPTD_SUMMARY=PASS tiers_passed=2/2` |
| 冻前 `verify-all` | `步骤通过 38 ❌ 失败 0` ∧ `结论：✅ 全部通过` ∧ `用例通过 875 跳过 2` |

### 1.4 冻后 `verify-all` ×2（槽内串行）

| 趟 | 步骤 | 用例 | 结论 | `[11]` | `[7]` | `[17]` | `[38]` |
|---|---|---|---|---|---|---|---|
| 冻后 1 | 步骤通过 38  ❌ 失败 0 | 用例通过 875  跳过 2 | 结论：✅ 全部通过 | PASS names=38 decl=38 gen=#67（逐字见 §5.2 附） | PASS live=3137b1d5728eeb97 decl=3137b1d5728eeb97 | PASS undeclared_hit=0 files=84 sites=85 hit=0 | PASS legs=2/2 |
| 冻后 2 | 步骤通过 38  ❌ 失败 0 | 用例通过 875  跳过 2 | 结论：✅ 全部通过 | 同上（逐字相同） | PASS live=3137b1d5728eeb97 decl=3137b1d5728eeb97 | PASS undeclared_hit=0 files=84 sites=85 hit=0 | PASS legs=2/2 |

**两趟判词行逐字 diff**：`✅ 两趟**逐字相同**`（`diff 空（关键判词行 7 条全等）`）

### 1.5 冻结（守卫四格 ＋ 世代交叉断言 ＋ 位移表）

```
[1] 冻前 步骤通过 38 ❌ 失败 0 ∧ 结论 ✅ 全部通过                                    ==> PASS
[2] [11] prereg=PASS gen=#67 prose=OK ∧ [7] BASELINESHA=PASS live=8c53d8da067472cb ==> PASS
[3] 模板占位符全在 fmt 表内(21 处) ∧ 段标记 1/1/1 ∧ FROZEN CF=2 CC=1 AL=5 ∧ 冻前基线件占位符=0 ==> PASS
[4] sha ≠ 8c53d8da067472cb=yes ∧ CURRENT-STATE 含 gen=#67=yes ∧ 残留占位符=0 ∧ RE-FROZEN#67≥1 ==> PASS
```
- **世代交叉断言**：`世代交叉断言通过：树上 #66 == GENS[#67][prev]`
- **位移表**：`相对开工前变化的位 = ['pf'] ｜inputs_fp = ab58dd6165a454ca981f2761bc5643f3424a647381bf7af8a83f180591d0b8ec ｜BRIDGE_SRC_FP = d697b1e10ff48881` ⇒ **`changed == ['pf']`**（零产品位移，只环成员动）
- **新基线**：`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` = **`3137b1d5728eeb97`**／**976,590 B**｜`CURRENT-STATE:9` = `gen=#67 sha16=3137b1d5728eeb97`｜`w67-freeze.DONE`（`FREEZE_RC=0`，`frozen_at=2026-09-25 00:47:51`）
- 其余冻后核对器：`BASELINEGEN=PASS decl_gen=#67 file_newest_gen=#67`｜`BASELINEDUP=PASS n=0`｜`ARMLOG_SHA=PASS required=5 declared=5`｜**`COLUMN_FLOOR=PASS reason=decl==frozen-and-decl>=corpus pass=3 fail=0`**

### 1.6 覆盖面与指纹

| 量 | before | after | 归因 |
|---|---|---|---|
| `FPHYG_COVERAGE_N` | 163 | **165** | `close-wave.sh` 白名单 **+2 行**（`pts-pages-guard.sh` ＋ `run-pts-pages-legs.sh`） |
| `infp.sh list` 行数 | 163 | **165**（**`err` 0 行**） | 同上（**"两条静默消失"闭合**） |
| `inputs_fp` | `2fa59979bcdd0148…` | **`ab58dd6165a454ca…`** | ①白名单 +2 行（`close-wave.sh` 自含于覆盖面）②新增两件**内容** ⇒ **无第三处**；随后 `run-pts-pages-legs.sh` 修 `PIPEFAIL` 陷阱再挪一次（**覆盖面不变 165**） |

### 1.7 收尾链

- **`~/w21-verify/w67-POST.done`**：`size=0 ｜ mtime=2026-09-25 10:10:38.456694792 +0800 ｜ mode=644（真 stat 见 ~/w160a/logs/53-post-done.txt）`
- **推送**：`<未取>`
- **app-local**：`<未取>`
- **两处哨兵**：`/tmp/bridge-frozen.flag` ＋ `~/wfp-runs/bridge-frozen.flag` ⇒ 补 **`BASELINE=#67`** ＋ **`BASELINE_SHA16=3137b1d5728eeb97`**，`cmp` = **<未取>**
  ⚠️ **键名逐字说明**：本文件既有约定是**裸键**，其中 **`SHA=` 是桥（`wpfgfx_cor3.so`）的值**，与 **`BASELINE_SHA16=`（基线件 `ACCEPTANCE-BASELINE.md` 的 16 位截断）** 是**两个不同的主体** —— 不许读成同一个量。

---

## §2 判据与两极化（含判否）

- **判据先行**：`~/w160a/criteria.md`（`157d595fb78fad4c`）写于**任何补丁之前**（mtime 早于 `patches/` 全部产物）：B1–B9 基线、P1–P11 正极、N1／N2a／N2b／N2c 反极、**判否条件 5 条**、§7 变更记录。
- **正极**（全部成立）：`names=38 decl=38 gen=#67 dup=0 order=OK prose=OK prereg=PASS`｜`coverage_n=165`｜`FILES_N=165`｜`bash -n` ×4 rc=0｜`[38] PTS_GUARD=PASS legs=2/2`。
- **反极**（**真跑 4 条**，见 `~/w160a/apply.sh`）：
  | 腿 | 反向操作 | 读数 |
  |---|---|---|
  | N1 | 删 `run_step "PTS-PAGES"`、**保留声明** | `rc=1`：`count-mismatch(现场 37 ≠ 声明 38)` ＋ `name-set-differs` ＋ `prose-mismatch`；**两趟逐字节相同** |
  | N2a | 删 `fp_inputs()` 新加**两行** | `coverage_n=162`（回开工基线） |
  | N2b | 只删**一行** | `coverage_n=163`（**一行一件**：逐件归因） |
  | N2c | 把那行换成产物路径 `obj/leaked-artifact.sh` | `FP_INPUTS_HYGIENE=FAIL reason=coverage-contains-artifacts`，`rc=1`（**清单有牙**） |
- **装置级两极化**（`~/w160a/polarity-display.sh`，改动件自己的判据）：正极（造一个**命令行真带 `:233`** 的假进程）⇒ **`rc=2`**、`device=NOINFO reason=display-occupied display=:233 pid=2149847` ✅；负极（空闲）⇒ **`rc=0`**、`device=memok`、`X_UP=yes` ✅ ⇒ `POLARITY pos=yes neg=yes`。
  ⚠️ **口径收窄**：`fp-inputs-hygiene` **不判件数** ⇒ "删两行"那一格是**逐件归因读数**，"件数必须 == 165"由本车道判据 ＋ 落仓声明在守；**不许**把 `coverage_n=162` 读成"那颗牙红了"（它的牙由 N2c 证）。

---

## §3 本波**独立发现**的装置级缺陷（每条都有现场判词）

| # | 缺陷 | 现场判词 | 修法 |
|---|---|---|---|
| 🔴 **1** | **`GROUPS` 撞 bash 内置只读变量**（进程组 ID 列表）⇒ `GROUPS=("A:24,23")` **静默无效**，`echo "LEGS: ${GROUPS[*]}"` 打的是 **GID 列表**（现场 `LEGS: 1000 24 27 30 46 122 135 136 4`，与 `id -G` **逐字相同**）⇒ 9 行 `MISSING-SHIM`、**一条腿都跑不出来且无报错** | `G1 MISSING-SHIM …/dlls/1000.libwpfwin32.so` …（9 行） | **换名 `LEG_GROUPS`**；机械证 `~/w160a/repro-groups.sh`（对照组 A 换名 ⇒ `len=1`；对照组 B 原名 ⇒ `len=9` 且与 `id -G` 同）。**`D-G119` 家族新实例** |
| 🔴 **2** | **`PIPEFAIL-SIGPIPE` 陷阱**：`run-pts-pages-legs.sh:85` 的 `if tr … \| grep -q -- "$DISPLAY_NUM"; then` 是**末段早退** ⇒ `pipefail` 下 `rc≠0` ⇒ 那个 `if` 可能**恒假** ⇒ **显示占用检查静默失效**（装置会在别人占用的显示号上开跑＝假绿方向） | gate1 `[17]`：`PIPEFAIL_SIGPIPE=FAIL undeclared_hit=1 files=84 sites=86 hit=1` ＋ `UNDECLARED_HIT …/run-pts-pages-legs.sh:85` | **去管道**，先取变量再 `case`（`case` 不早退）⇒ 修后 `PASS undeclared_hit=0 sites=85 hit=0`。**改代码、不是改声明** |
| 3 | 分组传参形态错：`A:24`／`A:23` 拆成两个 argv ⇒ 下游读成 `ARM=A`/`KS=A` | `G1 MISSING-SHIM …/dlls/A.libwpfwin32.so` | 改成 `A:24,23`（一个 group 一个 argv） |
| 4 | 显示占用**自匹配**（`D-G103` 族）：槽里的子壳命令行也带 `PTS_GUARD_DISPLAY` ⇒ 原口径只排 `$$`/`$PPID` **不够** | `device=NOINFO reason=display-occupied display=:236 pid=2064672`（**那个 pid 是我自己的子壳**） | 排**整条祖先链**（`/proc/<pid>/stat` 第 4 列递归） |
| 5 | 转换器按 `session.txt` 的**目录**找 `app_g*.log` ⇒ 日志在 `$W/logs/<tag>/` 而 `$OUTDIR` 里没有 ⇒ 读不到原始日志 ⇒ `native_gap=0` ⇒ **假红** | `PTS_GUARD=FAIL fails=native-ledger-absent(PTS_GAP n=0)`（真值：原始日志 `PTS_GAP entry=` 命中 **1**） | 加 `SESS_LOGDIR` ＋ 转换前**镜像**原始日志到 `$OUTDIR` ⇒ 现读 `native_gap=1` |
| 6 | A 臂需 `$DLLS/A.libwpfwin32.so` 存在（A ＝ 现权威五件，但装置仍要那个副本） | `G1 MISSING-SHIM` | `~/w160a/stage-arms.sh` 运行时装配（＝当前权威件**同字节**副本，自证 `app=fc60c34d51fd9247 == arms/A`） |

⇒ **一句话**：装置**原样落仓会假绿**（#1／#2／#3／#5）／**假红**（#4／#5）—— 全在本波实测抓到并修掉。

---

## §4 ⚠️ 射程边界（**如实，不许读成绿**）

1. **证据/装置 20 件不在 `fp_inputs()` 覆盖面**：`build/MilBridge/tests/PtsPagesProbe/evidence/` **16 件**（不含指纹保护）＋ 装置四件共 **20 件**不在 `fp_inputs()` 覆盖面 ⇒ **本步对『有人改了这 20 件中的任何一件（含 `leg_*.env` 证据）』没有射程**（改了照样绿）。
   两条候选修法（**本波不扩，只声明**）：**(i)** 把证据目录作为**声明语料**纳入覆盖面（只在"有意重产"时挪指纹）；**(ii)** 把 `[38]` 从"读预置证据"**升级为"自己跑腿"**（那样才真能咬住 `A1/A2/A3` 被改回 —— 这是 `D-G122` 的原始意图；代价 ≈45 s/趟）。
2. **本步只保证"止损还在"，不保证"该被真实现"**（真缺口是 `TASK-0302`）；抓不到"下游真缺口被顺手 stub"。
3. **落地前预置的流程义务**：证据目录须由**波内前置**产出，否则本步 `NOINFO legs-dir-absent`（＝❌）。本波已把 16 件证据**留仓内并提交**（否则新克隆上必红）。
4. **`UNWIRED`（如实声明）**：装置 `run-pts-pages-legs.sh` **在仓内且被 `[38]` 用到**，但**不在覆盖面**；它"改了也不会红"这一点与第 1 条同源。

---

## §5 教训与自伤（**逐条留痕**）

### 5.1 本波特有教训

① **`DECL` 抽取器是 `head -1` ⇒ 新世代声明行必须插在「当前第一行 DECL」之前**：`verify-all-step-check.sh:73-83` 的 `decl_line()` = `sed … | head -1`。本车道第一版把新行插在 `#64` 那行前（当时它正好是最新行），而 `#65` 后又插了一行更靠前的 ⇒ 重锚后我的新行落到 `#65` 之下 ⇒ 工具读 `decl=37 gen=#65`（现场 38 步）⇒ `VERIFYALL_SELF=FAIL count-mismatch(38≠37)`。**修法**：动态取"文件里第一行 DECL"当锚 ＋ `hits==1`。**这是 `D-G131` 的射程**（`#65` 前 → `#65` 后 → `#66` 后 **三次重锚同一件**）⇒ 已把"**落仓第一步 = 现取基点 ＋ 重锚**"写进 `~/w160a/land.sh` 第 1 节（**默认路径**，不是特例）。
② **`prev_pf` 必须取"上一代冻后值"，不许取本波现值**：我一度把它填成 `cbd1884faeb4837e`（＝`#67` 整波 close-wave(20:09:24) 的**产物**）⇒ `pf_required=True` 那条断言**恒假/恒真**（**判据主体＝被测物**，`D-G119` 同族）。**真值 = `29ad6d7cf3246938`**（现读：基线件 `# RE-FROZEN #66` 块「九位」行 ＋ 该块「相对 `#65` 冻结值：`pf` `59ba7d2997fcdd62` → `29ad6d7cf3246938`」）。
③ **`w67-pre.sha`（开工前快照）必须在整波**之前**取**：我那张快照是在整波（20:09:24）**之后**拍的 ⇒ 两头都是波后值 ⇒ `changed==[]` ⇒ `pf_required=True` 当场红（`本代要求"只有环成员 pf 变"，实得 changed=[]`）。**修法**：`pf` 格改回 `#66` 冻后值 `29ad6d7cf3246938` ⇒ `changed == ['pf']` ✅。
④ **`column-floor-check.sh:156` 的 `extract_newest_block()` 是无行首锚的"出现次数截断"**：`awk '/RE-FROZEN #/{ if(seen==1) exit; …}'`；块内正文若出现该字样 ⇒ **提前截断**，紧随其后的 `# COLUMN-FLOOR`×2／`# COLUMN-CORPUS`×1／`# ARM-LOG-SHA`×5 **全被排除** ⇒ `COLUMN_FLOOR=NOINFO reason=frozen-block-has-no-COLUMN-FLOOR-line`。**我这一代模板第 19 行**（FROZEN 段内那句 `` `# RE-FROZEN #NN` ``）**恰好命中**；对照 `#66` 模板 **0 命中**（同类提醒写在 RECORD 段）⇒ **模板独有触发条件，但脆弱点在抽取器**。**补一条更致命的形态**：**BANNER 段出现该字样 ⇒ 抽块会在标题行之前退出（块为空）**。
   **修法**：① 改词（语义一字不改）＋ 把提醒移到 RECORD 段；② `build-record.py` **硬断言**（现读：`标题行 = [10]（须恰 1）｜'RE-FROZEN'+'#' 形态行 = []（须 ⊆ 标题行）｜BANNER 段 = []（须 0）`）；③ **端到端对照**（我实现了抽取器的**逐字循环语义**）：修好的模板 ⇒ 块 **49** 行、`CF=2/CC=1/AL=5` ✅；**坏的中间态备份** ⇒ 块 **9** 行、`CF=0` ⇒ **复现故障**。
   ⚠️ 本注**故意不把那串字样原样写出来**（第一次修就是这样把它引回来、被硬断言当场抓住）。

### 5.2 🔴 冻结件损坏事故（**二级损伤**，须逐字留痕）

- **链条**：① 冻结器第一次跑（`prev_pf` 错）在 `changed==[]` 处**未写盘**停；② 修 `prev_pf` 后第二次**写盘成功**（`931fdabd0f595660`），但**写盘后** `COLUMN_FLOOR` 那格红 ⇒ `FRC=1`、**无 `DONE`**；③ 我为"回到冻前态"重跑，从中间态备份里取 `[#66 块起点:]` 重写基线件 ⇒ **连带删掉文件开头的 54 行 `BASELINE-HEADER`** ⇒ 基线件变 `d03384a94b2c8d84`，而 `CURRENT-STATE:9` 仍声明 `8c53d8da067472cb` ⇒ `BASELINESHA=FAIL`。
- **二级损伤的唯一来源 = "从中间态备份手工拼接"**（不是冻结器、不是抽取器）。**采纳纪律**：**冻结基线件一旦被误写 ⇒ 停手、报主控，由主控从 git 取回那一世代的逐字节原件回灌；车道不许手工重建 header 或从中间态备份拼接。**
- **主控回灌（已做，现读）**：原件来源 = `~/netTest/GitProj/WPFOnLinux` 的 `git cat-file -p HEAD:samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` ⇒ **`8c53d8da067472cb`／963,724 B**；三重断言（现盘 == 受损态 ∧ 原件 == 期望 sha ∧ 字节数）＋ `temp+rename`。回灌后 `BASELINESHA=PASS live=decl=8c53d8da067472cb`。
- **我"故意不掩盖"的两格**（留痕）：事故期间 `CURRENT-STATE:9` **保持** `gen=#66 8c53d8da067472cb`（不改成受损态、也不假装已冻）；`DONE` **不写**。
- **附议（`[Next]` 方向，本波不做）**：`w27-freeze.py` **不备份基线件** ⇒ 建议写 `B` 之前先留一份 **`B.pre-freeze.<gen>.bak`**（让"回滚"不必依赖 git 克隆是否恰好有那一代）。

### 5.3 本车道**三处自伤**（如实）

| # | 自伤 | 为什么危险 | 怎么防 |
|---|---|---|---|
| 1 | **两极化第一版里"正极成立"其实是被另一个真实残留命中的**（`sleep 300 "$D"` 语法无效 ⇒ 我造的假进程**根本没起来**） | **结论对、机制错** —— "我以为装置在测 A，其实在测 B"，本仓最危险的形态之一 | 修复后**正负两档都要有"装置自证打在哪个 pid/display"**（现读 `pid=2149847`／`display=:233`） |
| 2 | 未显式设 `PTS_GUARD_DISPLAY` ⇒ 两档都撞默认 `:237` | 会把"被占用"与"装置故障"混成一谈 | 两档都显式传显示号；先**只读**证明目标号空闲 |
| 3 | **本车道自己留下了 `Xvfb :237` ＋ `xfwm4 :237`**（`ppid=1`、无 X 客户，20:0x 起） | **"起显示只 `:23x`"这条硬规则的第一个违反者是本波自己** | 已**按 PID** 收干净（先 TERM 后核对）；未动别人的 `:99`／`:97`；收后本车道 `:23x` 族**零残留** |

---

## §6 `NOINFO`（逐条）

| # | `NOINFO` | 原因 |
|---|---|---|
| 1 | 冻后 `verify-all` 的 `dynamic_trace` | 工具自报 `dynamic_trace=NOINFO`（"真 `--trace` 那一路"要整趟带 trace，不在本波射程）—— 如实照抄，**不当绿也不当红** |
| 2 | app-local 判词**词面** | 判词行仍是 **`MISMATCH`**（由波外 6 条 `UNEXPECTED[DECL-GAP-EQ]` 触发）；**硬判据** `STALE=0 ∧ DIVERGENT=0` **达成**。**照实报、不粉饰**；"词面 ≠ 硬判据"已由主控另立在册缺陷 |
| 3 | `[38]` 对"证据件被改"的射程 | 见 §4 第 1 条：证据/装置 20 件不在覆盖面 ⇒ **本步无射程**（`NOINFO`-类的射程缺口，不是绿） |

---

## §7 大白话小结（≤6 行）

1. `PTS-PAGES` 接进第 `[38]` 步（**落地前预置**）：四处声明 ＋ 判据件 ＋ 装置六件 ＋ 证据 16 件全部落仓，`38 ✅ / 0 ❌`，`[38]` **真绿**（`PTS_GUARD=PASS legs=2/2`，洋红 54,454／49,864 与前序观测逐位吻合）。
2. **冻结完成**：`# RE-FROZEN #67`，基线 `3137b1d5728eeb97`；**位移只有 `pf`**（零产品位移）；`inputs_fp` `2fa59979… → ab58dd6165a454ca…`（覆盖面 163 → **165**，两条"静默消失"闭合）。
3. 装置**原样落仓会假绿/假红**，本波实测抓出并修掉 **6 处**（最狠的是 `GROUPS` 撞 bash 内置只读变量 ⇒ 装置全聋且无报错）。
4. 我**弄坏过冻结件**（二级损伤），已由主控从 git 回灌复原；纪律已采纳：**基线件损坏 ⇒ 停手、由主控回灌**。
5. 两条射程边界如实写死：**证据/装置 20 件无指纹保护**；`[38]` 只保证"止损还在"，不保证"该被真实现"。
6. 报告末行机读：见下。

LANE=W160A TASK=0721 R_TOUCHED=11+1 DONE=yes NOINFO=3

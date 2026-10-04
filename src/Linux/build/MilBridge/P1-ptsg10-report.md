# `P1-ptsg10-report.md` —— `t73` 交件：`g10_name_check()` **去写死名字**（形态判据 ＋ 在册名单牙 ＋ 判词行必在场）

写者 `scribe`（attempt 1／`e659c9f7-a592-489b-9afb-351ed5703932`）｜一切读数**现取、自算**，每格带亚秒 `ts=`
⚠️ **归属如实记（本件基线不是本席所写）**：本席 `21:47:42` 复现到「判据过时红」现场（`rc=1`、输出**只有** `PTS_G10_NAME=FAIL header=LoCreateContext observed=unknown`、**判词行缺席**）后，**队长于 `ts=2026-09-28T21:48:52.587+0800` 接管本单**并落了第一版（提交 `e1c06ad`「t73（队长接管）—— 消 `PTS_G10_NAME` 判据过时红：`g10_name_check` 去自指、不再早退」）：**去自指 ＋ 不早退 ＋ 无名 ⇒ `NOINFO`** 三件已落地，但那一版把**「具名（无论是否在册）⇒ `PASS`」** —— 本席在同一 task 名下补的正是这条**缺掉的另一半牙**（在册名单）＋ 第 `28` 条写回。两版在同一反极输入上的成对读数见 §3。

## §0 一句话
`g10_name_check()` 不再与**写死的一个名字**对拍：无名 ⇒ `NOINFO(frontier-unnamed)`（**不算红也不算绿**）；具名 ∧ **在在册名单内**（名单源＝native `k_pts_entries[]`，**内容锚**）⇒ `PASS`；具名 ∧ **不在册** ⇒ `FAIL` **并点名**（**进 `rc`**）；名单源取不到 ⇒ `NOINFO(roster-source-unreadable)`（**永不当绿**）。**判词行 `PTS_GUARD=` 四态全在场**。

## §1 现取（写前／写后成对，`stat` ＋ `sha16` ＋ 行数）
| 件 | 写前 | 写后 | 判据 |
|---|---|---|---|
| `build/MilBridge/tools/pts-pages-guard.sh` | `9b20ca0b40f6943f`／**389** 行／26554 B／`644`（`ts=21:51:28.430`） | **`885f22a7025bc622`**／**474** 行／33741 B／`644`（`ts=21:52:27.711`） | `git diff --numstat` ＝ **`91 6`** |
| `build/MilBridge/HANDOFF-NEXT.md` | `753e60f457a3e81c`／**586** 行／176865 B（`ts=21:53:26.9`） | **`e8ad9bb432b59af7`**／**587** 行／177454 B | `numstat` ＝ **`3 0`**（§4） |

- 写前备份（**任何写之前**）：`~/w281-scribe/bak/pts-pages-guard.sh.pre-t73`（`cmp IDENTICAL`，`sha16 9b20ca0b40f6943f`）、`~/w281-scribe/bak/HANDOFF-NEXT.md.pre-t73`（`cmp IDENTICAL`，`sha16 753e60f457a3e81c`）；两件写前 `stat -c %h` ＝ **1**；落盘一律 `temp + rename` 且**显式保 `644`**。
- **删行归因（6 行，全部是代码行）**：`local dir="$1" obs n_names`／旧 `n_names=` 那一行／旧无名分支的 `echo`／旧 `PASS` 的 `echo`／`g10_name_check "$dir" || true`／旧用法行。**prose 历史 0 删**：队长那条 `⏪ dated 更正（队长…）` 块、`【t14】` 段、件头判据表**一字未删**（更正一律**加行**，§2）。
- 全量 `sha256`：`pts-pages-guard.sh` ＝ `885f22a7025bc622…`（交件消息给全 64 hex）；`HANDOFF-NEXT.md` ＝ `e8ad9bb432b59af7…`（同上）。

## §2 判据改动（形态**四态**；改法＝**加行** ＋ 换函数体）
件头**加两行**（旧句原样保留，只在其后追加更正）：
```
#   G10b（⏪ `t73`／scribe 2026-09-28 加牙）具名 `entry=` **在在册名单内**（名单源＝native `k_pts_entries[]`，内容锚）  否 ⇒ FAIL(off-roster)（**红并点名、进 rc**）
#   ⏪（`t73`／scribe，2026-09-28）上面 `G10` 那句的「**不进 rc**」须**按三态读**：`NOINFO`（无名／名单源不可读）**不进 `fails`**，但按本件第 `32`–`35` 行自declared 的判序（「有红先红…无红但有"判不了" ⇒ `NOINFO`」）**折进 `cannot`** ⇒ 判词行此时是 `PTS_GUARD=NOINFO`（rc=2）——**既不算绿也不算红**；`FAIL(off-roster)` 则**进 `fails`** ⇒ `PTS_GUARD=FAIL`。
```
**名单源（内容锚，无行号、无字面名字）**：`sed -n '/^static const char \*const k_pts_entries\[\] = {/,/^};/p' $ROSTER_SRC` ⇒ 现取 **10** 个在册名（`roster_names`）；`ROSTER_SRC` 默认由 `BASH_SOURCE` 上溯仓根解析，可用 `PTS_G10_ROSTER_SRC` 覆盖（两极化腿④用）。

| 输入 | `PTS_G10_NAME` | 判词行 | rc |
|---|---|---|---|
| 无名（只 `unknown`） | `NOINFO reason=frontier-unnamed` | `PTS_GUARD=NOINFO … cannot=g10-name-frontier-unnamed` | **2** |
| 具名 ∧ 在册 | `PASS observed=<名> names=1 roster=10` | `PTS_GUARD=PASS`（不被扰动） | **0** |
| 具名 ∧ **不在册** | **`FAIL frontier=<名> off-roster=<名> roster=10`** | **`PTS_GUARD=FAIL … fails=g10-name-off-roster(<名>)`** | **1** |
| 名单源不可读 | `NOINFO reason=roster-source-unreadable src=…` | `PTS_GUARD=NOINFO` | **2** |

**修前／修后（本席现取，捕获式）**
```
ts=2026-09-28T21:47:42.6+0800  修复前（队长接管**之前**的现盘件，本席首跑）
  rc=1 ｜ 输出仅 1 行：PTS_G10_NAME=FAIL header=LoCreateContext observed=unknown（件头具名与现取前沿不一致 ⇒ 红并点名） ｜ **PTS_GUARD= 缺席**（早退）
ts=2026-09-28T21:52:36.0+0800  修复后（落盘件，**默认**名单源解析、无 env）
  rc=2 ｜ PTS_G10_NAME=NOINFO reason=frontier-unnamed（…三态中的「算不出」：**不算红也不算绿**）
        ｜ PTS_GUARD=NOINFO legs=2/2 fails=- cannot=g10-name-frontier-unnamed diag=- direction=in-file phase=degraded
```
⇒ 验收①：**不再因「前沿无名」而红**（`FAIL` → `NOINFO`），**判词行在场**（`PTS_GUARD=` 四态全印）；且**没有**把「判不了」读成绿（判词是 `NOINFO`／rc=2，不是 `PASS`）。

## §3 两极化真跑（**仓外**夹具 `/tmp/t73-fx*`，跑完即删；腿①②③④ 输出原样）
夹具与读数**成对**：判据级（`--g10-name`）与整步级（`--legs`，腿件＝真证据**副本** ＋ 合成 `app_g1.log`）。
```
ROSTER_FIRST_NAME=CreateInstalledObjectsInfo（现取自内容锚）  该名在本判据件正文里出现 grep -c = 0
腿①整步·在册名(默认名单源) rc=0 ts=21:52:39.958   PTS_G10_NAME=PASS observed=CreateInstalledObjectsInfo names=1 roster=10
                                                  PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=- direction=in-file phase=degraded
腿②整步·不在册名(默认名单源) rc=1 ts=21:52:40.084  PTS_G10_NAME=FAIL frontier=NotAnEntryZZ off-roster=NotAnEntryZZ roster=10（具名行**不在在册名单**内 ⇒ 红并点名；名单源=/home/…/src/WpfGfx.Linux.Native/src/win32_pts.c）
                                                  PTS_GUARD=FAIL legs=2/2 fails=g10-name-off-roster(NotAnEntryZZ) cannot=- diag=- direction=in-file phase=degraded
腿③整步·真证据副本(无名)   rc=2 ts=21:52:40.199   PTS_G10_NAME=NOINFO reason=frontier-unnamed … ；PTS_GUARD=NOINFO … cannot=g10-name-frontier-unnamed
腿④名单源不可读(env 指空)  rc=2 ts=21:52:40.261   PTS_G10_NAME=NOINFO reason=roster-source-unreadable src=/tmp/t73-fx2/nonexistent-pts.c frontier=CreateInstalledObjectsInfo
夹具清除：ls -d /tmp/t73-fx2 ⇒ fixture-dir-removed-ok（三批夹具 `/tmp/t73-fx`／`fx2`／`fx3` 均已删）
```
**「不是放宽」的机器证（两条，互为反极）**
1. 用**在册名**（且该名在判据件正文里出现 **0** 次）⇒ `PASS` ⇒ 判据**由名单源驱动**，不是由件头残留的字面驱动。
2. 用**不在册名** ⇒ **必红并点名**（腿②）⇒ 没把断言删掉、也没把阈值放松；同一输入下**队长那一版**（＝写前备份件 `9b20ca0b40f6943f`）给的是 **绿**：
```
队长版（写前件）: PTS_G10_NAME=PASS observed=NotAnEntryZZ names=1  ＋ PTS_GUARD=PASS … ⇒ rc=0   ← 放宽
本席修后件     : PTS_G10_NAME=FAIL frontier=NotAnEntryZZ off-roster=NotAnEntryZZ roster=10 ＋ PTS_GUARD=FAIL … ⇒ rc=1
（同一夹具、同一 `ts=21:53:43.8` 一前一后跑；夹具已删）
```
⇒ 本件的改法是**收紧**：写前件对「伪造/拼错的名字」判绿，修后件判红。另：**零名单不当绿**（腿④）＋ **无名不当绿**（腿③ 判词 `NOINFO`）。

## §4 第 `28` 条同趟：`HANDOFF-NEXT.md` 的 `cell=#1` 追写（**本单写域内**）
- 该格判据＝`bash ~/w153a/bin/infp.sh fp`（覆盖面指纹）；本件**在覆盖面内**（`close-wave.sh` 的 `fp_inputs()` 白名单）⇒ 改它**必须同趟**追写本格。
- 追写行（`cat >>` 纯追加，模式不动）：`⏪ **机器值契约更正 · cell=#1**：… ts=2026-09-28T21:53:26.916+0800 时 现值 ＝ 1d61fbe039e0f5f8a0f2384c57df13f41cc87928b093f135a537046d1e4a631b（命令：bash ~/w153a/bin/infp.sh fp）`
- **成对读数**：
```
ts=21:52:57.402  HANDOFF_MV=DIVERGED rc=1 cells=9 equal=6 manual=1 mismatch=2 reasons=,#1:covered-file-changed-since-ts,#3:external-state-changed-since-ts   ← 追写**之前**
ts=21:53:35.421  HANDOFF_MV=PASS     rc=0 cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none                                                ← 追写**之后**
fp 成对：本席改件后 ts=21:52:46.736 fp=47ac563b259f9c2e8caf17687af897459618d69fa28941ed03437b68012ee9c2
        追写瞬间 ts=21:53:26.916 fp=1d61fbe039e0f5f8a0f2384c57df13f41cc87928b093f135a537046d1e4a631b（写入前＝写入后逐位相同，ts=21:53:27.027 复读同值）
```
- ⚠️ **并发如实记（不是本件的过失，也不许当成本件的读数）**：追写期间 **`t74` 重冻结批正在并发写盘** —— `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`／`docs/CURRENT-STATE.md`（`mtime 21:53:01.44x`）／`build/MilBridge/known-red.json`／`build/MilBridge/tools/wave-freeze-consistency-check.py`／`build/MilBridge/tools/defect-registry-declared.tsv`（`mtime 21:53:01` 前后）在工作树里均为 `M`。其中**在覆盖面内**的两件（`known-red.json`／`wave-freeze-consistency-check.py`）**会把 `fp` 再次顶开** ⇒ 本格的现值**只在 `ts=21:53:35.421` 那一刻成立**；若其后这些件再变，**本格须再追写一次**（同一 `cell=#1`，dated 追加）。`#3`（`external-state-changed-since-ts`）同为该批的写盘所致（本席**未**改 `CURRENT-STATE.md`／`ACCEPTANCE-BASELINE.md`，写域外）。本席另读到 `HANDOFF-NEXT.md` 在本席动笔前已被**另一写者**追加（本席写的备份像＝**586** 行／`753e60f457a3e81c`，而 `ts=21:53:17` 时为 585 行）⇒ 本件末行是本席的，**其余追加行归属未核**。

## §5 四条不变量／两枚哨兵／模式守恒（全部现取）
```
ts=21:52:46.736  ^run_step "        = 62              （不变量①，不变）
ts=21:52:46.736  coverage(infp list)= 234             （不变量②，不变）
ts=21:52:46.736  # VERIFYALL-STEPS-DECL: 62 gen=#81   （不变量③，首条声明不变；`verify-all.sh:73` 行号**仅本次有效**）
ts=21:52:46.736  run_step "FP-MANIFEST-TEETH" … --expect 234   （不变量④，不变；`:1201` 行号**仅本次有效**）
哨兵：cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag ⇒ **IDENTICAL**；两枚 `sha16 386865f802c2a1ff`（本席**未写**哨兵；该值系他者 `20:54:08.76x` 所写，现取未变）
模式守恒（两口径成对）：`stat -c %a` ⇒ `pts-pages-guard.sh 644`／`HANDOFF-NEXT.md 644`；`git ls-files -s` ⇒ `100644 ce3951fb…`／`100644 7bead7a7…`
自伤牙复跑：`PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 declared=0 files=114 sites=100 hit=0 low=10 diag=5 safe=85 runs=12`（新加的名单比对用 **bash `case` 匹配**，**不**用 `printf … | grep -q` ⇒ 未引入 sigpipe 站点）
自测：`PTS_GUARD_SELFTEST=PASS pass=30 fail=0`（写前件同跑 ⇒ `pass=24 fail=0` ⇒ **旧 24 例一字未退化**，新增 6 格＝腿①②③ 三例 ＋ 两条点名/reason 断言 ＋ 腿④）
```

## §6 `static-jaws-check.sh` 复跑（`ts=21:52:41 → 21:53:44`；**并发期间**读数）
```
STATICJAWS=FAIL fails=1 n=31 excluded=31 noinfo=2 n_total=62
STATICJAWS_HIT      step=SENTINEL-SPEC  jaw=…/sentinel-spec-check.sh rc=1 stderr=0行 ms=291   ← 唯一红
STATICJAWS_NOINFO   step=FrameProbe-frame rc=2 ／ step=COLUMN-FLOOR rc=2
STATICJAWS_RAN      step=ARM-LOG-SHA rc=0 ms=66
STATICJAWS_EXCLUDED step=PTS-PAGES reason=display-or-legs cmd=bash build/MilBridge/tools/pts-pages-guard.sh --legs "$PTS_EVIDENCE_DIR"
```
- **`PTS-PAGES` 属「排除面」**：该牙的射程＝「已接线的**裸**静态牙」，`PTS-PAGES` 是**带参步**（`--legs`）⇒ 逐条点名 `reason=display-or-legs`。故「`PTS-PAGES` 相关步不再红」对本牙**不存在被判量**（`grep -c 'PTS\|pts' static-jaws-check.sh` ＝ **0**）；该步本体由本席**直接跑**并已给读数（§2：判据不再 `FAIL`，判词行在场，rc=2 `NOINFO`）。
- 唯一红 `SENTINEL-SPEC` **不是本件引入**：本件一字未碰哨兵（`cmp IDENTICAL`／`sha16 386865f802c2a1ff` 前后同值）；哨兵内容系他者 `20:54:08` 改写。
- `ARM-LOG-SHA` 此刻 `rc=0`、`COLUMN-FLOOR` 此刻 `rc=2`：均为 `t74` 重冻结批**并发写盘中途**的瞬时读数（`known-red.json`／`ACCEPTANCE-BASELINE.md` 在飞），**归因该批、不是本件读数**，不作为任何结论。

## §7 写域／未做（边界）
- **实写 3 件**：`build/MilBridge/tools/pts-pages-guard.sh`、`build/MilBridge/HANDOFF-NEXT.md`（**仅** `cell=#1` 追写）、`build/MilBridge/P1-ptsg10-report.md`（本件，新建）。
- **未动**（写域外，逐件可核）：`verify-all.sh`、`build/close-wave.sh`、`docs/ROUTES.md`、`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`、`build/MilBridge/arm-logs/`、`src/**`（只读）、两枚哨兵；**未**改 `TASK-0007` 判据文本（那是 `W8` 真反转的事）；**未**跑整趟门禁、**未**跑 `dotnet`／构建／应用／显示位；**未** `git add`／`commit`／`push`（提交归队长）。进程无残留（夹具与临时件均在 `/tmp`，已删）。
- 工作树里另有**非本席**差异：`docs/ROUTES.md`（`mtime 21:51:26`）、`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`／`docs/CURRENT-STATE.md`（`21:53:01`）、`build/MilBridge/known-red.json`／`wave-freeze-consistency-check.py`／`defect-registry-declared.tsv`、`?? build/MilBridge/P1-w7-frontier-verify.md` ⇒ **写域内存在未提交差异，归属未核**（逐件点名如上，本席未读未改）。

## §8 `NOINFO` 具名清单（既不算绿也不算红）
1. `PTS_G10_NAME=NOINFO reason=frontier-unnamed`（**现世界形态**：`app_g1.log` 只有 `entry=unknown`×2）⇒ 判词 `PTS_GUARD=NOINFO` rc=2。
2. `PTS_G10_NAME=NOINFO reason=roster-source-unreadable`（名单源／表头锚取不到；腿④ 真跑）。
3. `static-jaws`：`FrameProbe-frame`／`COLUMN-FLOOR` 两格 `rc=2` 记 `NOINFO`（后者系重冻结批在飞）。
4. 未跑整趟门禁 ⇒ 本件**不声称**门禁整体绿（`STATICJAWS_SCOPE` 自己就这么写着：本牙绿≠整趟绿）。

## §9 残留字面自查（**零承重**，逐行定性）
```
grep -n 'LoCreateContext|CreateInstalledObjectsInfo' build/MilBridge/tools/pts-pages-guard.sh
  31:#         「假 stub 也不能让判据变绿」—— 链上下一个真缺口 `LoCreateContext` 仍在 ⇒ 降级仍是真的）    ← `D3` 诊断**历史理由**（prose，不被任何代码读）
  125:  #   （判据从自己的注释取"期望名"），且在前沿**结构性无名**时（`t63` 把 `entry=LoCreateContext`       ← 队长 `⏪` 块里的**历史叙述**（prose，不被任何代码读）
命中数：LoCreateContext=2（两行皆为注释）／CreateInstalledObjectsInfo=0
```
**零承重的机器证**：判据**唯一**的名单来源是 `roster_names()` 对 `src/WpfGfx.Linux.Native/src/win32_pts.c` 的内容锚抽取（旧 `sed` 自指解析已删除）；两极化腿①用的在册名在本件正文里**出现 0 次**却判 `PASS`，腿②用的名单外名（正文里也不存在）判 `FAIL` ⇒ 字面**既不能给绿也不能给红**。

---
**自证口径**：本件末行携带 `head -n -1 build/MilBridge/P1-ptsg10-report.md | sha256sum | cut -c1-16` 的值；全文 `sha256` 只在交件消息里给（第 `24` 条）。

## §10 ⏪ **dated 更正（`ts=2026-09-28T21:54` 队长裁定 → 本席 `21:54:55` 落盘）**：回正「无名」分支（**本条取代 §2 表格第 1 行与 §2 的修后读数行**）
队长裁定逐条（原文照录其要点，`t73` attempt `e659c9f7…` 的 in-flight 指令）：**① 保留** `G10b`（在册名单牙、`FAIL(off-roster)` 折 `fails`）—— 并明示这条正是他契约里要求而**他自报未达成**的那一条（「名单外⇒必红在原实现里并不存在」）；**② 回正**：**无名 ⇒ `PASS`**（无名是**算出来的状态**，不是「算不出」），**不许折进 `cannot`**；只有 `roster_names` **取不到名单**才是 `NOINFO`。**③ 两条精度**（他据 `verifier` 复核采纳、提交 `6e5cd74`）：(a)「端口层无任何 `Lo*` `DllImport`」**只在 `build/**` ＋ `src/**` 面成立**（声明在 **`upstream/wpf/**`**，`…/TextFormatting/LineServices.cs` 起）；(b)「`PTS-PAGES` **不读** `entry=`」这半句**按实改写** —— 它**确实读**（就是 `g10_name_check`），只是**只报形态**；「其绿对前沿位移零证据力」的**结论仍成立**。

**落法**：`g10_name_check()` 的无名分支 `NOINFO` ⇒ **`PASS form=unnamed reason=frontier-unnamed`**（`G10_RC=0` ⇒ **不进 `fails` 也不进 `cannot`**）；件头我上一趟加的那行与函数内 ⏪ 块**同趟改定为三支**（队长的原始 `⏪` 块与件头 `G10` 原句**一字未删**）；自测 ㉓ 的期望同趟由 `NOINFO` 改 `PASS`。**成对读数（写前／写后）**：`885f22a7025bc622`／**474** 行（`ts=21:52:27.711`，本席第一趟）⇒ **`59bffc8e5b5a621a`**／**483** 行（`ts=21:54:55.099`，第二趟）；对 `HEAD` 的 `git diff --numstat` ＝ `91 6` ⇒ **`100 6`**（删行仍 6，**全部是代码行**：匿名分支那一行 `echo` 等；**prose 0 删**）；`bash -n rc=0`；写前备份 `~/w281-scribe/bak/pts-pages-guard.sh.pre-t73b`（`cmp IDENTICAL`，写前 `%h=1`）。

**三支定型 ＋ 队长点名的三条成对读数（原样，`ts` 见行内）**
```
支①正极·现树（真证据目录，默认名单源）ts=2026-09-28T21:55:00.741+0800
  PTS_G10_NAME=PASS form=unnamed reason=frontier-unnamed（应用侧无具名 entry= ＝**算出来的形态**、不是「算不出」⇒ 本判据按形态通过；名字归因由 pts-gap-count-check.sh 的具名前沿判据承担）
  PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=- direction=in-file phase=degraded          rc=0
支②沙箱·具名但**不在册**（整步；腿件＝真证据副本）ts=2026-09-28T21:55:00.861+0800
  PTS_G10_NAME=FAIL frontier=NotAnEntryZZ off-roster=NotAnEntryZZ roster=10（具名行**不在在册名单**内 ⇒ 红并点名；名单源=/home/…/src/WpfGfx.Linux.Native/src/win32_pts.c）
  PTS_GUARD=FAIL legs=2/2 fails=g10-name-off-roster(NotAnEntryZZ) cannot=- diag=- direction=in-file phase=degraded   rc=1
支③沙箱·**毁名册源**（`PTS_G10_ROSTER_SRC` 指空路径）ts=2026-09-28T21:55:00.992+0800
  PTS_G10_NAME=NOINFO reason=roster-source-unreadable src=/tmp/t73-br/nonexistent-pts.c frontier=CreateInstalledObjectsInfo（**在册名单取不到 ⇒ 判不了 ⇒ 永不当绿**）   rc=2
支③'毁名册源·整步 ts=2026-09-28T21:55:01.007+0800
  PTS_GUARD=NOINFO legs=2/2 fails=- cannot=g10-name-roster-source-unreadable diag=- direction=in-file phase=degraded   rc=2
夹具清除：fixture-removed-ok（/tmp/t73-br）
```
⇒ **三支定型（终版）**：**无名 ⇒ `PASS(form=unnamed)`（不进 `fails`／`cannot`）｜名单源不可读 ⇒ `NOINFO`（折 `cannot`）｜具名但名单外 ⇒ `FAIL(off-roster)`（折 `fails`）**。`--selftest`（终版）＝ `PTS_GUARD_SELFTEST=PASS pass=30 fail=0`，其中 `G10·` 六格：`在册名 ⇒ PASS`／`不在册 ⇒ 必红`／`不在册 ⇒ 点名`／`无名 ⇒ 判词 PASS`（**改判后**）／`无名 ⇒ reason 在位`／`名单源不可读 ⇒ NOINFO rc=2`。
**如实记两点**：① 本席第一趟曾把「无名」折进 `cannot`（＝§2 表格第 1 行那个 `PTS_GUARD=NOINFO`），**已被本条取代**；队长给的理由（`NOINFO` 在门禁里同样是 ❌，而「前沿无名」在 `PTS` 长线上是长期常态 ⇒ 等于用 `NOINFO` 造长期红）**入册**。② §3 里「队长版对名单外名判绿」那条**仍然成立**（那是「在册名单」这条牙的**增益**证明，与「无名」分支无关）。

## §11 第 `28` 条（**第二趟**）＋ 终态读数
```
cell=#1 追写（第二趟，guard v2 之后＝最后一次覆盖件写盘之后）：
  PRE  587 行／e8ad9bb432b59af7／177454 B／644／%h=1（备份 ~/w281-scribe/bak/HANDOFF-NEXT.md.pre-t73b，cmp IDENTICAL）
  ts=2026-09-28T21:55:1x+0800  fp 现值 ＝ 4dc922684b575124675234713df9f033814ba8483e32fe717530cc3659158412（命令：bash ~/w153a/bin/infp.sh fp）
  POST 588 行／a512a6853372672c／177979 B／644／numstat **1 0**；写后复读 fp 同值（逐位相同）
HANDOFF-MV 成对：ts=21:52:57.402 DIVERGED rc=1 cells=9 equal=6 manual=1 mismatch=2 reasons=,#1:covered-file-changed-since-ts,#3:external-state-changed-since-ts（第一趟追写**之前**）
                ts=21:53:35.421 PASS     rc=0 cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none（第一趟追写**之后**）
                ts=21:55:22.835 PASS     rc=0 cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none（第二趟追写**之后**）
  ⚠️ 如实记：第二趟在「guard v2 写盘（21:54:55）」与「cell=#1 追写（21:55:1x）」之间**未取 HANDOFF-MV 读数**（不臆造中间态）；v2 使 `fp` 位移这件事由 fp 成对证明（`1d61fbe0…` → `4dc922684b575124…`）。
终态读数（现取）：run_step=62 ｜ coverage=234 ｜ `# VERIFYALL-STEPS-DECL: 62 gen=#81` 在位 ｜ `run_step "FP-MANIFEST-TEETH" … --expect 234` 在位
                    PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 sites=100 hit=0（新代码用 bash `case` 匹配，无 `printf | grep -q` 站点）
                    哨兵：cmp IDENTICAL；`sha16 80041e1c76d4cea8`（**他者** `mtime 21:53:39.145/.147` 所写，本席从未写哨兵；本席早前读数 `386865f802c2a1ff` ⇒ 期间被他者改过，如实记）
static-jaws（**终版复跑** ts=21:55:43→21:56:24）：`STATICJAWS=PASS n=31 excluded=31 noinfo=1 n_total=62` rc=0
                    唯一 NOINFO＝`FrameProbe-frame rc=2`（约定）；`PTS-PAGES` 仍在排除面：`reason=display-or-legs cmd=bash build/MilBridge/tools/pts-pages-guard.sh --legs "$PTS_EVIDENCE_DIR"` ⇒ 该步**不在**本牙被判量里，其本体读数见 §10 支①
                    （对照：本席第一趟 ts=21:53:44 读到 `FAIL fails=1`（唯一红 `SENTINEL-SPEC`）＝**他者哨兵改写期间**的瞬时态；该红随 `21:53:39` 的哨兵改写与他 `t74` 提交而消，**不是**本件的修改面）
```
**未做**（本件边界，逐条）：未跑整趟门禁、未跑 `dotnet`／构建／应用／显示位；未动 `docs/ROUTES.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`TASK-0007` 判据文本／`build/MilBridge/arm-logs/`／`src/**`（只读）／`verify-all.sh`／`build/close-wave.sh`／两枚哨兵；未 `git add`／`commit`／`push`（提交归队长；本席已把在飞件 `pts-pages-guard.sh` 终态值报给他）。三批夹具（`/tmp/t73-fx`／`fx2`／`fx3`／`br`）与临时件**全部已删**；`git status --porcelain` 里的其余差异属他者（`docs/ROUTES.md`／`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`／`docs/CURRENT-STATE.md`／`known-red.json`／`wave-freeze-consistency-check.py`／`defect-registry-declared.tsv`／`?? P1-w7-*.md` 等）**归属未核、本席未读未改**。

## §12 ⏪ 收口追记（`ts=2026-09-28T21:57:10` 现取）：队长提交与「本席写后他者再追加」的终态
队长已把本件三件提交为 **`7bccbf4`**「docs(#81): t73（scribe 版收口）—— pts-pages-guard 加 G10b 名册检查 + 无名分支回正为形态 PASS」，提交级 `numstat` ＝ `build/MilBridge/tools/pts-pages-guard.sh **100 6**` ／ `build/MilBridge/HANDOFF-NEXT.md **2 0**` ／ `build/MilBridge/P1-ptsg10-report.md **123 0**`（⇒ **提交级删行仍为 6，全在判据件的代码面**）。
- `pts-pages-guard.sh`：`HEAD` 版 ＝ **`59bffc8e5b5a621a…`／483 行**，与工作树**逐位相同**（`git diff --numstat` 空）⇒ 落定。
- `HANDOFF-NEXT.md`：本席写后**他者又追加一行**（`ts=21:55:36.408`，同值 `4dc92268…`）⇒ **终态 589 行／`90b7e0f8ac60a45d…`**；`HEAD` 笔里 `cell=#1` 两行＝`21:55:18.833`（**本席**）与 `21:55:36.408`（**他者**，值相同）。§11 里那个「588 行／`a512a6853372672c`」是**本席那次写入的瞬时值**，不与他者追加矛盾。
- `P1-ptsg10-report.md`：`HEAD` 版 ＝ 123 行（本席第一版）；本席**收口版** ＝ **165 行**（`git diff --numstat` ＝ `42 0`，纯追加）**仍在工作树（未提交）** —— 提交归队长。
- 复核（收口后现取，`ts=21:57:00.711`）：`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0 reasons=none` rc=0；`fp=4dc922684b575124675234713df9f033814ba8483e32fe717530cc3659158412`（与 `cell=#1` 现值逐位相同）；`DEFREG=PASS declared=223 route_ids=223`；`REPORTID=PASS files=230 ids=2188 declared=223`；`static-jaws` `STATICJAWS=PASS n=31 excluded=31 noinfo=1 n_total=62`（`ts=21:56:24.074`）。
**本件自证**：`head -n -1 build/MilBridge/P1-ptsg10-report.md | sha256sum | cut -c1-16` ＝ `1391ad2efb45c16d`（本行系末行；上列各节即被哈希的全文）

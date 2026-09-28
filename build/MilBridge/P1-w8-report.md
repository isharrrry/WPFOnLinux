# P1-w8-report —— W8：`TASK-0007` 判据成对反转（`t64`）

> **车道** `runner`／**任务** `t64`（attempt 1）。**写域** ＝ `build/MilBridge/tools/pts-pages-guard.sh`／`build/MilBridge/tests/PtsPagesProbe/evidence/`／本件。
> # 🔴 判词 ＝ **`NOINFO(reason=前置未达)`** —— **反转未做、未发绿、一个仓内件未改**。
> **依据（两处，逐字）**：① **契约自己写的分支**："若 `t63` 只是加了符号／**没跑出真实排版** ⇒ **不许发绿**，记 `NOINFO` 并说明缺什么（这是本仓在册禁忌：「用旧判据给真因发绿灯」）"；② **队长 `2026-09-28T20:58` 裁定**：「**不许做判据反转** …… 此时把判据反过来，就是把「洋红占位」判成绿 …… 按 `t64` 契约办：记 `NOINFO(reason=前置未达)`，并在册写清「**反转还缺什么**」…… 你**不必**为它重跑腿（`t63` 的 `leg_23/24` 成对读数就是依据）」。
> **一句话**：`TASK-0302` 的增量**作为能力真落地了**（`entry=LoCreateContext 3→0`、导出 `556→557`、进程内自检 `1`、两极化 PASS），**但它没让 23／24 两页进入真排版**（两页仍是**洋红占位**、应用仍抛 `PtsUnavailableException` ＋ `action=page-placeholder`）⇒ **反转会让"占位"被判绿** ⇒ 本件只把**反转包**写成可直接落地件（含本件**新发现**的第三方必改点：`G10` 具名对拍），并给**反极真跑的现取读数**。
> **读取时刻**：现取于 `2026-09-28T20:59:09–21:00:46 +08:00`，逐格带亚秒 `ts=`。

---

## §1 硬前置核对（`t63` 交付读数成对；**这是本件判 NOINFO 的事实基础**）

| 格 | 读数（`t63` 现取） | 判 |
|---|---|---|
| **能力真落地（机器证）** | 前沿跳数成对：`entry=LoCreateContext` **3 → 0**；导出面 **556 → 557**（新增 `LoDestroyContext`）；`PTS_SELFCHECK=1`；两极化 `LOC_POLARITY=PASS`（`create=0/非空`、`destroy(own)=0`、重复/未知`0xdeadbeef`/NULL/出参空 **四条拒绝面全中**、`ls_context_live=0` 零泄漏） | **是**（不是"只加符号"） |
| **两页是否真排版（本任务的门槛）** | `t63` **after** 两腿：`leg_24 magenta=55058 colors=852`／`leg_23 magenta=50468 colors=844`（**before** 为 `54826/851`／`50236/843` ⇒ **略升**）；应用侧仍 `[PTS-UNAVAILABLE] site=FlowDocumentView.DocumentPage … action=page-placeholder` ＋ `[HC-UNHANDLED] #1 PtsUnavailableException` | **否** |
| **下一站** | `PTSGAP_FRONTIER_STATE=UNNAMED`（`entry=unknown`；紧接着的 LS 入口全部**未导出**，`t69` 接手具名化） | 未到位 |
**⇒ 门槛判断**：**「真排版」不成立**（`洋红 ≠ 0`、具名行在位、native 台账仍在）⇒ **反转不许做**（做了就是把占位判绿）。

---

## §2 现状成对读数（**修前／修后＝同值**：本席本趟未改任何仓内件）

| 格 | 现取（`ts=2026-09-28T20:59:09.485780420`） | `ts=2026-09-28T21:00:46.140174912`（复核） |
|---|---|---|
| 判据件 `build/MilBridge/tools/pts-pages-guard.sh` | **`7074a774739efaf2`** | **同值** |
| `evidence/leg_23.env` | **`9fb8af8d6fdebb45`** | **同值** |
| `evidence/leg_24.env` | **`afb1081916bd0d0d`** | **同值** |
| `evidence/device.txt` | `6d2cf7572e7323b7`（内容 `X_UP=yes display=:237`） | 同值 |
| 模式守恒（两口径） | `stat -c %a` ＝ `644` ×3 ／ `git ls-files -s` ＝ `100644` ×3 | **逐件成对一致** |

**逐腿三列成对（现取，`magenta`／`colors`／`ns`）**：
```
leg_23  alive=yes app_rc=143 magenta=50236 colors=843 ns=HandyControlDemo.UserControl.RichTextBoxDemo  ae=140697 ink=428205
leg_24  alive=yes app_rc=143 magenta=54826 colors=851 ns=HandyControlDemo.UserControl.FlowDocumentDemo  ae=221857 ink=423547
```
两腿 `NAMED` 行同为：`NAMED managed_unavail=1 err=-10000 native_gap=1 native_err=-10000` ⇒ **降级形态在位**（reversed 的前置不成立）。

### 🔴 一条**现取更正**（scout 在册读数已过期）
scout 写「现跑 `bash …pts-pages-guard.sh --legs …/evidence` ⇒ `PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=- direction=in-file phase=degraded`（`rc=0`）」。**现取不再是这个**：
```
$ bash build/MilBridge/tools/pts-pages-guard.sh --legs build/MilBridge/tests/PtsPagesProbe/evidence
PTS_G10_NAME=FAIL header=LoCreateContext observed=unknown（件头具名与现取前沿不一致 ⇒ 红并点名）
$ echo rc=$?   ⇒ rc=1        # ★ 输出**只有这一行**：判词行 `PTS_GUARD=` **缺席**
```
**成因**：`t63` 让前沿从 `LoCreateContext` 移走（应用侧只记 `unknown`），而判据件**件头 `G10` 的把关字面量**仍是 `entry=LoCreateContext` ⇒ `g10_name_check()` 判 `FAIL` ⇒ `main` 里 `g10_name_check "$dir" || return 1` **提前返回** ⇒ **连判词行都打不出来**。（同一条根因的另一面：`t20` 报的 `GATE_PROBE` 红是同族的"日志/源码换代"，已由 `t67` 修绿。）

---

## §3 旧口径 ⇄ 新口径：**件内原文**成对（判据件的自有机制，`t12` 已留位）

**① 旧（`phase=degraded`，今天在册）＝「止损还在即绿」**（件内 `:16-22` 与 `:193-196` 逐字）：
```
G4  leg 24 `magenta ≥ 20000`   否 ⇒ FAIL   ｜  G5  leg 23 `magenta ≥ 20000`  否 ⇒ FAIL
G8  leg 24 具名行 `[PTS-UNAVAILABLE] site=FlowDocumentView.DocumentPage` ∧ `err≠0`   否 ⇒ FAIL
G10 至少一条 native `PTS_GAP entry=LoCreateContext`                                  否 ⇒ FAIL
[degraded 分支]  [ "$mag" -ge "$MAGENTA_FLOOR" ] || fails+=(leg$k-placeholder-missing(…))
                 [ "${merr:-}" = "-10000" ]      || fails+=(leg$k-named-line(…))
                 [ "$ngap_total" -ge 1 ]         || fails+=(native-ledger-absent(PTS_GAP n=0))
```
**② 新（`phase=realized`，反转后应生效）＝「真排版才绿」**（件内 `:185-190`／`:211` 逐字）：
```
[realized 分支]  [ "$mag" -eq 0 ] || fails+=(leg$k-placeholder-still-drawn(magenta=$mag≠0∧phase=realized))
                 [ "${merr:-}" = "-" ] || [ -z "${merr:-}" ] || fails+=(leg$k-named-line-still-present(err=$merr))
                 [ "$ink" -gt 0 ] || fails+=(leg$k-no-real-ink(ink=$ink))   （缺 ink ⇒ cannot ⇒ NOINFO）
                 [ "$ngap_total" -eq 0 ] || fails+=(native-ledger-still-present(PTS_GAP n=$ngap_total∧phase=realized))
```
**③ 两期共用的不可变量 `I1`（三态完备性，`t12`）**：`(magenta>0 ∧ 具名行在位) ∨ (magenta==0 ∧ 无具名行 ∧ ink>0)`；两者都不成立（如"只降级不画"）⇒ **必红**。
⇒ 契约要求的「红条件同趟写死」＝ **realized 期的反面**，逐字即：**`洋红 ≥ 20000` ∨ 具名行在位 ∨ `native_gap ≥ 1`**（与上面 realized 分支的三条 `fails+=` **一一对应**，本件已用**反极真跑**验证其命中，见 §5）。

---

## §4 反转包（**未落地**；落地时**逐条同趟**改，含本件新发现的第三方必改点）

> **应用前置（门槛，缺一不可）**：在同一装置上**真跑**得到两页 **`magenta=0` ∧ 无具名行 ∧ `native_gap=0` ∧ `ink>0` ∧ `alive=yes`**，且现取 `grep -c 'magenta=0' …/leg_23.env …/leg_24.env` **== 2**（现取：**0／0**）。**今天不满足**。

| # | 件 | 改法（逐字） | 为什么必须同趟 |
|---|---|---|---|
| ① | `pts-pages-guard.sh:43` | `# PTS-DIRECTION: … phase=degraded` → **`phase=realized`**（**只翻这一个 token**；与牙自己 `--selftest` 造 realized 副本用的是同一条 `sed`） | `PHASE` 由这一行现取（`:84`）⇒ 翻它就是翻判据方向 |
| ② | 同上，件头 `G4/G5/G8/G10` | 把"占位必须存在"的绿条件改写为**realized 形**（含点名旧句的 **dated 更正**）：**旧句「止损态即绿」必须逐字点名为已废**（本仓体例：不许静默改口径） | 件头是**承重文本**：`G10` 还被 `g10_name_check()` 当**机读锚**用（`:109`） |
| ③ | 同上，`g10_name_check()` | **必须重划**：现口径要求「至少一条 `PTS_GAP entry=LoCreateContext`」，而 realized 期台账应为 **0** ⇒ **两者不相容**；而且**今天它已经独立把守卫判红**（`PTS_G10_NAME=FAIL header=LoCreateContext observed=unknown`，`rc=1` **且判词行缺席**，§2）。建议改成「realized 期：**无** `PTS_GAP` 行」＋「degraded 期：具名 == 当时的**在册前沿名**（内容锚，不写死 `LoCreateContext`）」 | 不改它 ⇒ **翻转后守卫仍会在 G10 早退**，永远拿不到 realized 判词 |
| ④ | 同上，红条件句 | 逐字写死：**`洋红 ≥ 20000` ∨ 具名行在位 ∨ `native_gap ≥ 1`**（并保留 `I1` 三态不可变量） | 本仓既有做法：**绿红同趟**，禁止只改一半 |
| ⑤ | 落地后**同趟** | 跑 `--selftest`（现取 `PTS_GUARD_SELFTEST=PASS pass=24 fail=0`，其中**已含** `realized·占位仍在 ⇒ FAIL`／`realized·具名行仍在 ⇒ FAIL` 两腿）＋ 用 §5 的三份夹具复核两向 | 自测是**合成**用例；真树两向必须另跑（§5 已备好夹具） |

---

## §5 反极真跑（**原样输出**）＋ 旧口径盲区 ＋ 方向反转（同一批夹具，`ts=2026-09-28T21:00:25.759576342`）

**夹具（**仓外**，`~/t64-runner/fx-*`，未落仓）**：`fx-real`（真排版形：`magenta=0` ＋ 无具名行 ＋ `native_gap=0` ＋ `ink>0`）｜`fx-placeholder`（占位形：`magenta=25000` ＋ 具名行在位 ＋ `native_gap=1`）｜`fx-real-gap`（真排版形 ＋ 为满足旧 `G10` 而保留一条 gap 行）｜`guard-realized.sh` ＝ 判据件的**车道副本**（**只翻 phase 一个 token**，`diff` 现取**只有 1 行**）。

| 格 | 形态 | 原样判词（节选） | `rc` |
|---|---|---|---|
| **③** | **旧口径(degraded) × 占位形** | `PTS_G10_NAME=PASS …` ＋ **`PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=- direction=in-file phase=degraded`** | **0** |
| **④** | **新口径(realized) × 占位形**（**反极真跑**） | `PTS_GUARD=FAIL legs=2/2 fails=`**`leg24-placeholder-still-drawn(magenta=25000≠0∧phase=realized),leg24-named-line-still-present(err=-10000),leg23-placeholder-still-drawn(magenta=25000≠0∧phase=realized),leg23-named-line-still-present(err=-10000)`** | **1** |
| ⑤ | 旧口径 × 真排版形 | `PTS_GUARD=FAIL … fails=leg24-placeholder-missing(magenta=0<20000),leg24-named-line(missing-or-err=-),leg23-placeholder-missing(magenta=0<20000),leg23-named-line(missing-or-err=-),native-ledger-absent(PTS_GAP n=0)` | 1 |
| ⑥ | 新口径 × 真排版形（无 gap 行） | `PTS_G10_NAME=NOINFO reason=算不出来 …` ＋ **`PTS_GUARD=PASS … phase=realized`** | 0 |
| ⑦ | 新口径 × 真排版形（＋gap 行） | `PTS_G10_NAME=PASS …` ＋ **`PTS_GUARD=PASS … phase=realized`** | 0 |
| ① | 旧口径 × **仓内真证据** | `PTS_G10_NAME=FAIL header=LoCreateContext observed=unknown`（**判词行缺席**） | 1 |
| ② | 新口径 × **仓内真证据** | 同上（G10 先红，仍拿不到判词） | 1 |

**三条结论（机读、成对）**：
1. **反极红条件真的会咬**：④ 对占位形夹具**逐腿点名** `placeholder-still-drawn(magenta=25000≠0∧phase=realized)` ＋ `named-line-still-present(err=-10000)` ⇒ 契约要的"反极必须命中并点名"**成立**。
2. **旧口径 ＝ 盲区，且方向相反**：同一份占位夹具在旧口径下 **PASS**（③），而真排版夹具在旧口径下 **FAIL**（⑤）⇒ **两个口径互为镜像**（这不是"不够严"，是**判反了**）。
3. **`G10` 是反转的"硬绊脚"**：①／② 显示**今天**守卫已在 G10 早退（`rc=1`、无判词行）；⑥（无 gap 行的真排版夹具）能 PASS 但 `G10` 只给 `NOINFO` ⇒ 若不按 §4-③ 重划，**realized 期的判词与 G10 会长期互相打脸**。

---

## §6 纪律与不越域

- **本席本趟零仓内写入**（除本报告）：`pts-pages-guard.sh`、`leg_23.env`、`leg_24.env` 三件 sha16 **前后逐位同值**（§2）；`git status --porcelain` 里与 `pts-pages` 相关的唯一 `M` 是 `run-pts-pages-legs.sh` ⇒ **`t68`／scribe 的写入**，非本席。
- **未跑腿、未占槽、未起显示位**（本件全为纯读 ＋ 仓外夹具；队长明示"不必重跑腿"）；跑前现取（`ts=2026-09-28T20:59:09.485780420`）：`free -m` `available=5841MB`、`swapfree=1408MB`、`df -Pk ~` 余 `72697388 KB`（≫5 GB）；现取 `SLOT=FREE`。
- **未跑整趟门禁**；`src/**` **只读**（本趟零写入）；`docs/ROUTES.md`／`KNOWN-DEFECTS.md`／`declared.tsv`／两枚哨兵**一字未改**；模式守恒 `644`／`100644` 两口径成对。

---

## §7 `NOINFO`／未做（逐条具名）

1. **反转未做** ⇒ `NOINFO(reason=前置未达)`；**缺什么**＝**两页真排版**（`magenta=0` ∧ 无具名行 ∧ `native_gap=0` ∧ `ink>0` ∧ `alive=yes`，且 `grep -c 'magenta=0' … == 2`）⇒ 这要求 `TASK-0302` 再往前走（下一站就是 `t69` 要处理的**具名化**，再往后是真正的 LS 排版实现）。
2. **本件未改判据件**（故 `PTS_GUARD=` 的 realized 判词在仓内**不存在**，只在车道副本上预演）—— 这是**故意**的：契约与队长都要求"前置未达不许发绿"。
3. **`grep -c 'magenta=0'` 的现状**：仓内两腿 **`0`／`0`**（不满足 `== 2`）；**合成夹具** `fx-real` 上 **`1`／`1`** 且 realized 副本判 `PASS`（⑥/⑦）⇒ 判据机制**可达**，缺的只是产品读数。
4. **未复核** `t63` 的读数在其各自写入时刻是否为真（只引用；本件所有读数自取自算）。

---

## §8 我推翻了哪句话

1. **scout 的「现跑 `PTS_GUARD=PASS … phase=degraded`（`rc=0`）」** ⇒ **已过期**：现取 `rc=1`、输出**只有** `PTS_G10_NAME=FAIL header=LoCreateContext observed=unknown`、**判词行缺席**（成因＝`t63` 的前沿位移 vs 件头写死的 `LoCreateContext`）。
2. **「反转 ＝ 翻一个 `phase` token 就完事」** ⇒ **不完整**：必须**同趟**重划 `G10`（含 `g10_name_check()` 的机读锚），否则 realized 期**永远在 G10 早退**、拿不到判词（①/②/⑥ 三格现取为证）。
3. **「旧口径只是不够严」** ⇒ **更正为方向相反**：占位夹具在旧口径 **PASS**（③）、真排版夹具在旧口径 **FAIL**（⑤）⇒ 两个口径互为镜像；把 `phase` 翻转而不点名额旧句，等于**留下一条会发假绿的口径**。
4. **「`magenta>0` 与具名行同时在位 ⇒ 是"降级但没死"的中性状态」** ⇒ 在 realized 期它是**红**（`placeholder-still-drawn` ＋ `named-line-still-present`），而在 degraded 期它是**绿**（`I1` (a) 支）⇒ **同一读数在两期含义相反**，这正是"口径必须带期名"的现场例。

---

## §9 交件清单（每格带亚秒 `ts=`）

```
前置（引用 t63）    前沿 entry=LoCreateContext 3→0；exports 556→557；PTS_SELFCHECK=1；LOC_POLARITY=PASS
                    after 两腿 magenta=55058/50468（≠0）⇒ 真排版未达成 ⇒ NOINFO(reason=前置未达)
判据件 sha16        ts=20:59:09.485780420 → 21:00:46.140174912   7074a774739efaf2（前后同值）
leg_23.env sha16    9fb8af8d6fdebb45（前后同值）   leg_24.env afb1081916bd0d0d（前后同值）
PTS_GUARD 行        现取**缺席**：`PTS_G10_NAME=FAIL header=LoCreateContext observed=unknown`，rc=1（输出仅 1 行）
两腿三列            magenta 50236/54826 ｜ colors 843/851 ｜ ns RichTextBoxDemo/FlowDocumentDemo（成对）
矩阵（夹具，仓外）  ③旧×占位 PASS(rc=0) ｜ ④新×占位 FAIL(rc=1，逐腿点名) ｜ ⑤旧×真排版 FAIL(rc=1)
                    ⑥新×真排版 PASS(rc=0, G10=NOINFO) ｜ ⑦新×真排版+gap PASS(rc=0,G10=PASS) ｜ ①② 真证据 rc=1(G10 早退)
资源                ts=20:59:09 available=5841MB swapfree=1408MB df_kb=72697388 SLOT=FREE（本件零重活）
模式守恒            stat 644 / git 100644（guard ＋ 两腿 env 逐件成对）
```

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-w8-report.md | sha256sum | cut -c1-16`）= `95beb59de0d6e1fa`

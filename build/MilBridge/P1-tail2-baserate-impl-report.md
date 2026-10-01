# P1-tail2-baserate-impl-report —— 基线率闸**可比时间窗**（装置/测量）

> **车道**：`T-A60`（装置/测量子代理；本轮唯一写者）。任务：`build/MilBridge/tasks-tail2/T-A60.md`。
> **装置入口（在册件）**：`build/MilBridge/tools/baseline-rate-gate.sh`（**`1bad58c07a8264e6`**，**一字未改**）。
> **读取时刻**：全部读数现取于 **`2026-10-01T16:3x+0800`**（逐条带 `ts=`／命令原文在 §6）。
> **一句话**：把**在册速率**连同**取自真跑记录的**真实时间窗登记进**数据源件**，使闸判词由**缺窗 `NOINFO-NO-WINDOW`** 转为**可判定**（`FAIL/VOID-PREMISE` ①②并列点名 / `PASS` / `FAIL`＋`DRIFT` 点名）；**阈值/判据 `git diff` 零改动**；反例对照 **3 条**现取。
> **自报 sha16**：末行 `SELF-SHA16`（口径 = `head -n -1 … | sha256sum | cut -c1-16`）。

---

## §0 结论摘要

| 格 | 现取读数 |
|---|---|
| 闸（在册件） | `baseline-rate-gate.sh` **`1bad58c07a8264e6`**（与在册逐位同；`git diff` 空） |
| **在册速率（带真窗）** | `2/175@2026-09-23T10:04:58..2026-09-23T13:04:05+display=:185`｜`1/140@2026-09-28T18:39:39..2026-09-28T20:11:55+display=:238`｜`1/77@2026-09-28T06:39:59..2026-09-28T07:28:48+display=:186` |
| **判词（带窗）** | `BASELINERATE=FAIL`／`reason=VOID-PREMISE`（`registered_in_observed_ci=1`／`gate_closed=1`／`effect_impossible=1`）⇒ **可判定**（**如实 `FAIL` ＋ ①②点名**） |
| **判词（缺窗）** | `BASELINERATE=NOINFO`／`reason=NOINFO-NO-WINDOW`（`rc=3`）⇒ 由「不可判定」**转为可判定**的**唯一**输入 ＝ **补真窗** |
| 数据源件（**新建**） | `build/MilBridge/tools/baseline-rate-registered.tsv` **`b4f646b28369813e`**（34 行；`--cases` ⇒ `BASELINERATE_CASES=7 passed=7 failed=0`／`rc=0`） |
| **反例对照** | ① `22/27` ⇒ `PASS`（`required_n=43`）｜② `12/12` ⇒ `PASS`（`required_n=21`）｜③ `7/28` ⇒ `FAIL`＋点名 `DRIFT` |
| 阈值/判据改动 | **0**（`git diff -- build/MilBridge/tools/baseline-rate-gate.sh` **空**） |
| 相关闸 | `DEFREG=PASS declared=225 route_ids=225`（`rc=0`）｜`REPORTID=PASS files=336 ids=2243 declared=225`（`rc=0`） |

**自包含结论**：在册速率**本身带窗**后闸即**可判定**；在**现件代零命中观测**（`0/175`／`0/300`）下**闸恒判 `VOID-PREMISE`**（`observed(0) < effect(>0)` ⇒ **效应在现世界不可发生**，**结构必然**）——**这是「如实 `FAIL` ＋ 点名」而非「造一个 `PASS`」**（硬边界：永不假成功）。

---

## §1 ① 输入契约逐条现取（**件:行**）

**件**：`build/MilBridge/tools/baseline-rate-gate.sh`（**`1bad58c07a8264e6`**；以下行号**仅本次写入时刻有效**）。

| # | 契约项 | 现取落点（件:行） | 形态/口径（逐字） |
|---|---|---|---|
| 1 | **在册速率**解析 | `:119-130`（`parse_registered`）｜注释 `:120` | `` `R/N@时间窗` ⇒ (r,n,window)``；**缺 `@时间窗` ⇒ `window=None`**（`:130`） |
| 2 | 在册速率**缺窗判词** | `:157-158` | `NOINFO-NO-WINDOW 在册速率缺**时间窗**（形态须为 R/N@时间窗）⇒ 不许用它定 N（D-G118）` |
| 3 | 在册速率**形态非法** | `:153-154` | `NOINFO-PARSE registered不可解析（形态应为 R/N@时间窗）` |
| 4 | **`observed`** 解析 | `:112-117`（`parse_rn`）｜`:228-231` | `R/N`；空/不可解析 ⇒ `NOINFO-EMPTY-SAMPLE`（`:231`） |
| 5 | **`N` 定义** | 在册 `:159-162`｜现取 `:233-236`｜判据 `P1-task0201-criteria.md:49` | 分母＝**臂内入分母腿数**；重算 `N` 用**现取率** `:294-301` |
| 6 | **时间窗**语义 | 闸只存窗**字符串**（`:123-127`／`:156`）；语义在**判据件**：`P1-task0201-criteria.md:49` ＋ 其 `§14 F5`｜`P1-tail2-segv-recon.md §4.5`（`:203-208`） | 该件代/臂**自身的首腿 .. 末腿**（`ts_start..ts_end`）＋ `display=:<d>` |
| 7 | **`gate`/`effect` 常数落点** | 解析/域检查 `:241-253`；必填项 `:570-571` | 由 CLI 传入（`:559`）；域 `gate∈(0,1)`、`effect∈[0,1)`（`:249-252`） |
| 8 | **统计常数** | `ALPHA :51`｜`POWER :52`｜`Z_1S :53`｜`Z_2S :54` | `0.05`／`0.80`／单侧 `1.6448536`／双侧 `1.9599640` |
| 9 | **台账读点**（`--cases`） | `:314-357`（列 `:315-317`；列宽响亮失败 `:344-349`）｜入口 `main :555-577` | `name registered observed gate effect want_state want_rc want_reason_class`（8 列；新形态 +2 列） |
| 10 | **现取样本来源**（真跑记录列） | `~/w128a/runs.tsv` 列 `ts_end`(29)｜`~/t7-runner/runs.tsv` 列 `ts_end`(30)｜`~/w48a/runs.tsv` 列 `ts_end`(29) | `R/N` ＝ 按件代/臂去重计数；**窗** ＝ 该组 `ts_end` 首末（见 §2 旁证） |

> ⚠️ 本闸**不改任何输入契约**：`--registered` 仍要 `R/N@窗`，缺窗仍**响亮 `NOINFO`**（纪律 27：解析任一侧为空必须响亮失败，禁静默判等）。

---

## §2 ② 按在册口径补齐**可比时间窗**（数据）＋ 判词现取

### 2.1 真跑记录现取（**窗的旁证**，逐组）

`ts_end` 列现取（分组键 `arm|shim_check|disp`）：

```
$ awk -F'\t' 'NR>1{k=$3"|"$8"|"$5; …}' <runs.tsv>     # 取每组 ts_end 首/末
~/w128a/runs.tsv          gdb|abf6879c027c5e73|:185     n=175  ts_end 2026-09-23 10:05:30 .. 13:04:05
~/t7-runner/runs.tsv      nogdb|abf6879c027c5e73|:238   n=149  ts_end 2026-09-28 18:39:39 .. 20:11:55
~/w48a/runs.tsv           nogdb|abf6879c027c5e73|:186   n=77   ts_end 2026-09-28 06:41:25 .. 07:28:43
~/t204-captain/c2/runs.tsv nogdb|26da177686acb1f0|:237   n=346  ts_end 2026-09-30 01:08:58 .. 05:56:34
~/t204-captain/c2/runs.tsv nogdb|abf6879c027c5e73|:238  n=60   ts_end 2026-09-30 05:57:58 .. 06:30:55
```
（最后两行是**现件代**主臂与**成对修前臂**，与 `P1-tail2-segv-report.md §2/§4` 的窗逐字相符。）

### 2.2 数据源件（**新建**）：在册速率**带真窗**

`build/MilBridge/tools/baseline-rate-registered.tsv`（**`b4f646b28369813e`**／34 行）登记**在册速率 ＋ 真实窗**（`R/N@窗+display`），**只补数据与形态**；闸用**既有 `--cases` 接口**逐行现取（**闸零改动**）。

### 2.3 判词现取（**成对**：带真窗 vs 缺窗）

```
$ bash build/MilBridge/tools/baseline-rate-gate.sh \
    --registered '2/175@2026-09-23T10:04:58..2026-09-23T13:04:05+display=:185' \
    --observed 0/175 --gate 0.035537 --effect 0.011429        # ① 带真窗
BASELINERATE=FAIL
BASELINERATE_REASON=VOID-PREMISE ① ci_upper(0.0152) < gate(0.0355);以② observed(0.0000) < effect(0.0114) ⇒ 该效应在现世界不可发生
window=2026-09-23T10:04:58..2026-09-23T13:04:05+display=:185  observed=0/175
registered_in_observed_ci=1  gate_closed=1  effect_impossible=1  caliber_disagreement=0
BASELINERATE_RC=1

$ bash build/MilBridge/tools/baseline-rate-gate.sh \
    --registered '2/175' --observed 0/175 --gate 0.035537 --effect 0.011429    # ② 缺窗
BASELINERATE=NOINFO
BASELINERATE_REASON=NOINFO-NO-WINDOW 在册速率缺**时间窗**（形态须为 R/N@时间窗）⇒ 不许用它定 N（D-G118）
BASELINERATE_RC=3
```

**⇒ 判词现取**：`baseline-rate-gate.sh` 由 **①→ 带真窗 ⇒ 可判定 `FAIL/VOID-PREMISE`**（**如实 `FAIL` ＋ ①②点名**）；**②→ 缺窗 ⇒ `NOINFO-NO-WINDOW`**（**具名前置**：缺时间窗）。**在册速率带真窗后，闸不再落 `NOINFO`**。

### 2.4 ④-前置：**前提客观上不可全满足者**（**如实判，不造窗**）

在**现件代零命中观测**下（`0/175`／`0/300`，命中 `k=0`）：

- `observed(0.0000) < effect(0.011429)` **恒成立** ⇒ `effect_impossible=1` ⇒ **`VOID-PREMISE` ②** 是**结构必然**（**不是**缺数据）。
- ⇒ 该样本**永不可能**给出 `PASS`（`PASS` 要求 `observed ≥ effect`）；**能给的、也是唯一正确的**判词就是**如实 `FAIL/VOID-PREMISE`**。
- **具名前置（不得造）**：要让闸脱离 `VOID-PREMISE`，须**换一个有命中的同窗样本**（`observed ≥ effect`）或**该效应量在现世界确实可发生**——**本件不为此编造任何窗/数**。

---

## §3 ③ 反例对照（**≥2 条**；证明**闸不是恒判**）

| # | 档 | 输入（`registered` / `observed` / `gate` / `effect`） | 现取判词（原文） |
|---|---|---|---|
| ① | **`PASS` 档** | `24/27@2026-09-23T17:25:50+08:00+display=:221` / `22/27` / `0.70` / `0.30` | `BASELINERATE=PASS`／`registered_in_observed_ci=1`／**`required_n=43`**（`rc=0`） |
| ② | **`PASS` 档** | 同上 `registered` / `12/12` / `0.70` / `0.30` | `BASELINERATE=PASS`／**`required_n=21`**（`rc=0`） |
| ③ | **`FAIL`＋点名档** | 同上 `registered` / `7/28` / `0.70` / `0.30` | `BASELINERATE=FAIL`／`REASON=DRIFT 历史速率落在新样本 CI 之外（registered=24/27=0.8889 ∉ 现取 CI [0.1268,0.4336]） + VOID-PREMISE ①…;以②…`（`rc=1`） |

- ⇒ **闸在两档都真跑到**（`PASS` 与 `FAIL`＋点名），**不是恒判 `VOID-PREMISE`**（`D-G89` 同族：反例对照）。
- **附一条 `VOID-PREMISE`（只让②成立）**：`27/30@2026-01-01T00:00:00+08:00` / `27/30` / `0.70` / `0.95` ⇒ `FAIL`／`REASON=VOID-PREMISE ② observed(0.9000) < effect(0.9500)…`（证明②单独可触发）。

---

## §4 ④ 阈值/判据 `git diff` **零改动**

```
$ git diff -- build/MilBridge/tools/baseline-rate-gate.sh | wc -l
0
$ git diff -- build/MilBridge/tools/baseline-rate-cases.tsv | wc -l
0
$ sha256sum build/MilBridge/tools/baseline-rate-gate.sh | cut -c1-16
1bad58c07a8264e6        # == 在册值（一字未改）
$ bash build/MilBridge/tools/baseline-rate-gate.sh --selftest | tail -1
BASELINERATE_SELFTEST=PASS
$ bash build/MilBridge/tools/baseline-rate-gate.sh --cases build/MilBridge/tools/baseline-rate-cases.tsv | tail -2
BASELINERATE_CASES=21 passed=21 failed=0
BASELINERATE=PASS            # rc=0
```
- **零改动**逐条：① 阈值（`gate`/`effect` 域、`ALPHA`/`POWER`/`Z_*`）**未动**；② 判据（`parse_registered`／`NOINFO-NO-WINDOW`／`VOID-PREMISE` 两条／三态）**未删未放宽**；③ 在册台账 `baseline-rate-cases.tsv` **未动**（`git diff` 空；`--cases` 仍 `21/21`）。
- 新增物＝**数据源件 1 个**（`baseline-rate-registered.tsv`，**只含数据行**）＋ **载体报告 1 个**（本件）。**`git status` porcelain**：`?? build/MilBridge/tools/baseline-rate-registered.tsv`（数据源件，新建）／`?? build/MilBridge/P1-tail2-baserate-impl-report.md`（本载体）／`?? build/MilBridge/tasks-tail2/T-A60.md`（派单件，前已在）——**零跟踪件改动**（`git diff --stat` 空）。

---

## §5 ⑤ 相关闸

```
### DEFREG  rc=0
DEFREG_DECL=n=225 route_ids=225 grammar=D-[A-Z][0-9]*[a-z]?(-[A-Za-z0-9]+)*
DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN keys=-
DEFREG=PASS declared=225 route_ids=225（…无未声明编号）
### REPORTID  rc=0
BOOK_ENTRY_BINDING required=5 present=5 missing=0
REPORTID=PASS files=336 ids=2243 declared=225 glob=build/MilBridge/*report*.md
```
（两闸在**新建数据源件落盘后**现跑；均 `rc=0`。）

---

## §6 复跑命令（逐条可重放；**零 `dotnet`／零 `X`／零槽**）

```bash
N=/home/links-dev/netTest/GitProj/WPFOnLinux; cd "$N"
# ── ① 契约定点（行号仅本次有效）─────────────────────────────
sed -n '112,130p;146,162p;241,253p;555,577p' build/MilBridge/tools/baseline-rate-gate.sh
# ── ② 真跑记录现取窗（分组 ts_end 首末）─────────────────────
awk -F'\t' 'NR>1{k=$3"|"$8"|"$5;if(!(k in a)||$29>a[k])a[k]=$29;if(!(k in b)||$29<b[k])b[k]=$29;c[k]++}END{for(k in c)printf "%-42s n=%3d %s..%s\n",k,c[k],b[k],a[k]}' ~/w128a/runs.tsv
awk -F'\t' 'NR>1{k=$3"|"$8"|"$5;if(!(k in a)||$30>a[k])a[k]=$30;if(!(k in b)||$30<b[k])b[k]=$30;c[k]++}END{for(k in c)printf "%-42s n=%3d %s..%s\n",k,c[k],b[k],a[k]}' ~/t7-runner/runs.tsv ~/t204-captain/c2/runs.tsv
awk -F'\t' 'NR>1{k=$3"|"$8"|"$5;if(!(k in a)||$29>a[k])a[k]=$29;if(!(k in b)||$29<b[k])b[k]=$29;c[k]++}END{for(k in c)printf "%-42s n=%3d %s..%s\n",k,c[k],b[k],a[k]}' ~/w48a/runs.tsv
# ── ③ 判词现取（带真窗 / 缺窗 成对）────────────────────────
bash build/MilBridge/tools/baseline-rate-gate.sh --registered '2/175@2026-09-23T10:04:58..2026-09-23T13:04:05+display=:185' --observed 0/175 --gate 0.035537 --effect 0.011429   # FAIL/VOID-PREMISE rc=1
bash build/MilBridge/tools/baseline-rate-gate.sh --registered '2/175' --observed 0/175 --gate 0.035537 --effect 0.011429                                                 # NOINFO-NO-WINDOW rc=3
# ── ④ 反例对照（PASS 档×2 / FAIL＋点名档×1 / VOID-PREMISE 只②×1）─
bash build/MilBridge/tools/baseline-rate-gate.sh --registered '24/27@2026-09-23T17:25:50+08:00+display=:221' --observed 22/27 --gate 0.70 --effect 0.30   # PASS required_n=43
bash build/MilBridge/tools/baseline-rate-gate.sh --registered '24/27@2026-09-23T17:25:50+08:00+display=:221' --observed 12/12 --gate 0.70 --effect 0.30   # PASS required_n=21
bash build/MilBridge/tools/baseline-rate-gate.sh --registered '24/27@2026-09-23T17:25:50+08:00+display=:221' --observed 7/28  --gate 0.70 --effect 0.30   # FAIL/DRIFT 点名
# ── ⑤ 数据源件（在册速率带真窗）用闸既有接口逐行现取 ───────────
bash build/MilBridge/tools/baseline-rate-gate.sh --cases build/MilBridge/tools/baseline-rate-registered.tsv   # 7 passed=7 failed=0 PASS rc=0
# ── ⑥ 零改动 / 相关闸 ────────────────────────────────────
git diff -- build/MilBridge/tools/baseline-rate-gate.sh build/MilBridge/tools/baseline-rate-cases.tsv | wc -l
bash build/MilBridge/tools/defect-registry-check.sh; echo $?
bash build/MilBridge/tools/report-id-domain-check.sh; echo $?
```

---

## §7 边界 / 主动披露 / `NOINFO`（逐条）

1. **窗的旁证 vs 在册形态**：数据源件的窗用**在册流转形态**（`P1-tail2-segv-recon.md §4.5`／`P0-mvp-segv-report.md §13③/§14⑦` 逐字）；`runs.tsv` 无 `ts_start` 列 ⇒ 本件给的是**该臂 `ts_end` 列**的首末**作旁证**。`2/175` 的批级 `ts_end` 首＝`10:04:58`、gdb 臂组内首＝`10:05:30`；`1/77` 在册起点含链起时刻 `06:39:59`、臂自身首＝`06:41:25`——**两处差异已在件内旁注**。
2. **本件只出「可判定」判词，不宣称任何产品结论**：`VOID-PREMISE` ⇒ **不得据此宣称改善/率变低**（`registered_in_observed_ci=1`：在册速率**落在**观测 CI 内）。
3. **`NOINFO`（具名）**：① **未跑任何重活腿**（不看新命中）——窗与计数的旁证取自**已在盘的真跑记录**；② **`term`／`stop-signo11` 两支现场不可达**（与本件无关，如实列）；③ 本件**未改任何判据/阈值**，故**无需**重跑整趟 `verify-all`；④ 数据源件为**新建**（未纳入 `fp_inputs()` 显式清单）⇒ **不移动 `inputs_fp`**（如实划界，非暗改）。
4. **`temp+rename`＋写前对账**：新建数据源件经 `*.tmp` → `mv -f` 落盘；闸与在册台账**读前读后逐位相同**（`1bad58c07a8264e6`／`1a2df056f5677344`）。
5. **不越域**：未动 `verify-all.sh`／`build/close-wave.sh`／`upstream/**`／`build/shims/**`／`samples/**`；未 `git add/commit/push`；未跑 `dotnet`；进程未涉（无腿、无 `X`）。

---

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-baserate-impl-report.md | sha256sum | cut -c1-16`）= `b182069f3e310a25`

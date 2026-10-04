# W46K 报告 —— 波 `#46` **冻后** `verify-all` 两趟

车道路径 = `/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（下称 `$R`）。
本件**只读**：没有冻结、没有重钉、没有重建、没有跑 `integration-wave.sh`。
写盘仅两处：`$HOME/w46k/**`（日志/等待器/预检）＋ 本报告。

---

## 0. 结论（先给判词）

| 项 | 读数 |
|---|---|
| 冻结标记 | ✅ **等到** —— 首次命中 **2026-09-19 21:50:05** |
| 冻后第 1 趟 | ✅ **rc=0**｜25 步全绿（失败 **0**）｜871 用例通过 / 2 跳过｜**848 s** |
| 冻后第 2 趟 | ✅ **rc=0**｜25 步全绿（失败 **0**）｜871 用例通过 / 2 跳过｜**851 s** |
| **失败步名** | **空**（两趟都没有 `❌` 步） |
| `COLUMN_FLOOR=` | **红 → 绿**（`FAIL` → `PASS`） |
| `ARM_LOG_SHA=` | 两趟都 `PASS` —— ⚠️ **冻前那趟它也是 `PASS`**，见 §4-B |

⇒ **冻结生效、冻后两趟同趟全绿。** 唯一的"任务书预期与现场不符"是 §4-A/§4-B 两条，如实点名。

---

## 1. 冻结标记：时间与依据行

### 1.1 等待方式
`$HOME/w46k/wait-freeze.sh`：每 **60 s** 一轮（上限 45 min），日志 `$HOME/w46k/freeze-marker.log`。
判据 = 任务书给的**两条标记的析取**，其中标记 1 是**合取**（`m1a ∧ m1b`）：

- `m1a` = `grep -c 'BASELINE-FROZEN gen=#46' docs/CURRENT-STATE.md`
- `m1b` = `bash build/MilBridge/tools/baseline-sha-check.sh | grep -c 'BASELINEGEN=PASS decl_gen=#46'`
- `m2` = `grep -c 'RE-FROZEN #46' /home/links-dev/w21-verify/w46-record.txt`

### 1.2 命中时刻
```
2026-09-19 21:49:05 poll=10 m1a=0 m1b=0 m2=0
2026-09-19 21:50:05 poll=11 m1a=1 m1b=1 m2=0
MARKER-FOUND at 2026-09-19 21:50:05 (m1a=1 m1b=1 m2=0)
```
⇒ **命中 = 2026-09-19 21:50:05**，靠的是**标记 1（合取成立）**；**标记 2 全程为 0**（原因见 §4-A）。
等待用时 = 21:36:53 → 21:50:05 ≈ **13 分 12 秒**（远低于 45 min 上限，未超时）。

### 1.3 依据行（逐字原文 + 行号）

**(a) 机器行（`docs/CURRENT-STATE.md:9`）**
```
> BASELINE-FROZEN gen=#46 sha16=dd31a7701fc77829 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md
```

**(b) 两颗牙（`bash build/MilBridge/tools/baseline-sha-check.sh`，rc=0）**
```
BASELINESHA=PASS live=dd31a7701fc77829 decl=dd31a7701fc77829
BASELINEGEN=PASS decl_gen=#46 file_newest_gen=#46
BASELINE_BYTES=527577
BASELINEDUP=PASS n=0
```

**(c) 冻结块本体（`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md:6`）**
```
# RE-FROZEN #46 —— ✅ **当前冻结基线** —— 内容 = 修 **`D-G50`**（HC 组合框下拉"弹出即被关掉"…）
```

**(d) 与冻结同趟落地的外挂声明行（`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md:56-63`）**
```
# COLUMN-FLOOR arm=tab-oracle-anchor col=START      judged_min=615 released_min=194
# COLUMN-FLOOR arm=tab-oracle-anchor col=OVERFLOWED judged_min=421
# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=0cebc0afd5142fbf
# ARM-LOG-SHA arm=tab-anchor    sha16=1c43a12dcaa5718a
# ARM-LOG-SHA arm=tab-zero      sha16=9150c3a26a3cb789
# ARM-LOG-SHA arm=tab-rtl       sha16=92570318851ca7e8
# ARM-LOG-SHA arm=tline         sha16=e061054f73c9a2e7
# ARM-LOG-SHA arm=textlineproto sha16=4bceceeed570ba70
```
⇒ 这 8 行就是 `COLUMN-FLOOR` 第 ②/③ 格与 `ARM-LOG-SHA` 的**权威声明**（`column-floor-check.sh` 读它们）。

### 1.4 ⚠️ 一条"单看计数会假绿"的实测（我踩到过，写下来）
任务书给的标记 1 第一半是 `grep -c "gen=#46" docs/CURRENT-STATE.md ≥ 1`。**这个计数在冻结之前就已经 = 1**：
```
21:36:45  grep -c "gen=#46" docs/CURRENT-STATE.md  →  1
21:36:45  bash build/MilBridge/tools/baseline-sha-check.sh  →  BASELINEGEN=PASS decl_gen=#44
```
那一处命中是**叙述句**（`CURRENT-STATE.md:894` 提到 `verify-all` 同趟三处已改到 `#46`、`VERIFYALL_SELF=PASS gen=#46`），**不是**冻结行。
⇒ **必须用合取（`m1a ∧ m1b`）或改用 `BASELINE-FROZEN gen=#46` / `BASELINEGEN=PASS decl_gen=#46` 这样带机器牙的行**；只用 `grep -c "gen=#46"` 会**在冻结前就误判为已冻结**（我因此没有用这一条单独下结论）。

---

## 2. 两趟读数（冻后）

### 2.1 汇总

| # | 起 | 止 | `rc` | 耗时 | 步骤 | 用例 | 失败步名 |
|---|---|---|---|---|---|---|---|
| run1 | 21:52:20 | 22:06:28 | **0** | **848 s** | 通过 **25** / 失败 **0** | 通过 871 / 跳过 2 | **（空）** |
| run2 | 22:07:45 | 22:21:56 | **0** | **851 s** | 通过 **25** / 失败 **0** | 通过 871 / 跳过 2 | **（空）** |

日志：`$HOME/w46k/post-freeze-1.log`（sha16 `9832c2b753c6917b`）／`$HOME/w46k/post-freeze-2.log`（sha16 `1c878b1b9e898676`）。
两趟**严格串行**（run1 结束后 15 s 才起 run2），每趟前预检见 §2.4。

### 2.2 关键原文（两趟**逐字相同**，除 §4-C 点名的 4 行）

**`COLUMN_FLOOR`（本波的核心一格：红 → 绿）**
```
· 自报口径 COLUMN_FLOOR_OVERFLOWED_JUDGED_MIN=PASS arm=tab-oracle-anchor col=OVERFLOWED key=judged_min decl=421 frozen=421 corpus_min=421
· 自报口径 COLUMN_FLOOR_START_JUDGED_MIN=PASS arm=tab-oracle-anchor col=START key=judged_min decl=615 frozen=615 corpus_min=615
· 自报口径 COLUMN_FLOOR_START_RELEASED_MIN=PASS arm=tab-oracle-anchor col=START key=released_min decl=194 frozen=194 corpus_min=194
· 自报口径 COLUMN_FLOOR_CORPUS=PASS file=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux/tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json live=0cebc0afd5142fbf decl=0cebc0afd5142fbf
· 自报口径 COLUMN_FLOOR_ARMLOG=PASS n_decl=5 n_ok=5 bad=无
· 自报口径 COLUMN_FLOOR_SELFREPORT=PASS gate=747c078dbf040862 outdir=/tmp/column-floor.<随机>
· 自报口径 COLUMN_FLOOR=PASS reason=decl==frozen-and-decl>=corpus pass=3 fail=0 noinfo=0 selfreport=PASS reg=1fa4c4540fe1b69f base=dd31a7701fc77829 corpus=0cebc0afd5142fbf
```

**`ARM_LOG_SHA`**
```
· 自报口径 ARMLOG_SHA=PASS shape=flat logdir=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux/build/MilBridge/arm-logs required=5 declared=5 pass=5 fail=0 noinfo=0
```

**`BASELINEGEN` / `BASELINESHA`**
```
· 自报口径 BASELINESHA=PASS live=dd31a7701fc77829 decl=dd31a7701fc77829
· 自报口径 BASELINEGEN=PASS decl_gen=#46 file_newest_gen=#46
```

**`VERIFYALL_SELF`**
```
· 自报口径 VERIFYALL_SELF=PASS names=25 decl=25 gen=#46 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO vfile_sha16=87d2e05c92ac0c35
```

**结论行（两趟）**
```
 步骤通过 25  ❌ 失败 0
 用例通过 871  跳过 2
 结论：✅ 全部通过
```

### 2.3 25 步逐条（run1；run2 同）
`wpf-linux.sln ✅`｜`Commands.Tests ✅ 562/0`｜`Rendering.Tests ✅ 162/2`｜`Windowing.Tests ✅ 44/0`｜`HelloMil.Tests ✅ 19/0`｜`ManagedLayer.Tests ✅ 76/0`｜`Presentation.Tests ✅ 8/0`｜`verify-cmd-layout.py ✅`｜`tline-gate（五臂）✅`｜`PcLineOracle·Start 列 ✅`｜`FrameProbe-frame ✅`｜`BASELINE-SHA ✅`｜`ARM-LOG-SHA ✅`｜`BUILD-HYGIENE ✅`｜`DEFECT-REGISTRY ✅`｜`VERIFYALL-SELF ✅`｜`FP-INPUTS-HYGIENE ✅`｜`HIDDEN-ONLY ✅`｜`COLUMN-FLOOR ✅`｜`QUOTE-TRAP ✅`｜`PRODUCT-ENTRY ✅`｜`FRAME-PRESENCE ✅`｜`PIPEFAIL-SIGPIPE ✅`｜`THIRD-PARTY ✅`

### 2.4 每趟的开工预检（`$HOME/w46k/precheck.log`）
```
2026-09-19 21:51:19 precheck#1 dotnet=1 appgate=1 verifyall=0 Mem=2812MB
2026-09-19 21:51:49 precheck#2 dotnet=1 appgate=1 verifyall=0 Mem=2819MB
2026-09-19 21:52:20 precheck#3 dotnet=0 appgate=0 verifyall=0 Mem=3067MB
2026-09-19 21:52:20 PRECHECK-OK
…
2026-09-19 22:07:45 precheck#3 dotnet=0 appgate=0 verifyall=0 Mem=3115MB
2026-09-19 22:07:45 PRECHECK-OK
```
⇒ 两趟都在**现场静默**（别人的重活＝0）＋ `MemAvailable ≥ 1500 MB`（实测 3067 / 3115 MB）之后才开跑。
第 1–2 轮命中的是主控自己的**应用门禁 `gate-f2`**（`run-wpftextdemo.sh`）——我**没有**与它并发，等它退场才起 run1（这一点很重要：两趟应用门禁与 `verify-all` 都用 `:97`，并发会互相污染）。

收工读数：`MemAvailable=2989 MB`、`loadavg=0.54 0.89 0.98`、`pgrep -c -x dotnet = 0`。

---

## 3. 与"冻前那趟"的对照

冻前**权威那趟** = 主控的 `$HOME/w46h/06-verify-all-pre2.log`（sha16 `d17c114b20345183`，21:32 → **21:46** 完成）——
它就是冻结器 `w27-freeze.py <日志> … '#46'` 的 `<日志>` 实参，故为**唯一正确的对照基线**。

| 项 | 冻前（pre2） | 冻后 run1 | 冻后 run2 |
|---|---|---|---|
| `rc` | 非 0（**1 红**） | **0** | **0** |
| 步骤 | 通过 **24** / 失败 **1** | 通过 **25** / 失败 **0** | 通过 **25** / 失败 **0** |
| 失败步名 | **`COLUMN-FLOOR`** | **（空）** | **（空）** |
| 用例 | 871 通过 / 2 跳过 | 871 / 2 | 871 / 2 |
| `BASELINEGEN` | `PASS decl_gen=#44 file_newest_gen=#44` | `PASS decl_gen=#46 file_newest_gen=#46` | 同 run1 |
| `BASELINESHA` | `PASS live=ff3990dafa582831` | `PASS live=dd31a7701fc77829` | 同 run1 |
| `COLUMN_FLOOR=` | `FAIL … pass=3 fail=1 noinfo=0 … base=ff3990dafa582831` | **`PASS … pass=3 fail=0 … base=dd31a7701fc77829`** | 同 run1 |
| `COLUMN_FLOOR_ARMLOG=` | **`FAIL n_decl=5 n_ok=4 bad= tline`** | **`PASS n_decl=5 n_ok=5 bad=无`** | 同 run1 |
| `ARMLOG_SHA=` | **`PASS`（required=5 declared=5 pass=5 fail=0）** | `PASS`（同） | 同 |
| `VERIFYALL_SELF` | `PASS names=25 decl=25 gen=#46 …` | 同 run1 逐字相同 | 同 |

**冻前失败原文（原样，供对账）**
```
  COLUMN-FLOOR                 ❌  (rc=1)
      COLUMN_FLOOR_ARMLOG=FAIL n_decl=5 n_ok=4 bad= tline
      COLUMN_FLOOR=FAIL reason=floor-lowered-or-below-corpus-or-gate-selfreport-mismatch pass=3 fail=1 noinfo=0 selfreport=PASS reg=1fa4c4540fe1b69f base=ff3990dafa582831 corpus=0cebc0afd5142fbf
 步骤通过 24  ❌ 失败 1
 结论：❌ 失败项：COLUMN-FLOOR
```

**机制解释（为什么这一格会红转绿）**：`column-floor-check.sh` 的四格判据里，
② = 读**最新 `# RE-FROZEN` 块**的 `# COLUMN-FLOOR` 行、③ = 语料 sha16 == 块的 `# COLUMN-CORPUS` 行。
冻前最新块还是 `#44` 的声明（`base=ff3990dafa582831`），而登记表已被本波**重钉**到 `reg=1fa4c4540fe1b69f`（判定行 421→**615**）⇒ 声明侧对不上 ⇒ `fail=1`；
冻结把 `judged_min=615 released_min=194`（START）、`judged_min=421`（OVERFLOWED）、`# COLUMN-CORPUS sha16=0cebc0afd5142fbf` 与 5 条 `# ARM-LOG-SHA` **同趟插进 `#46` 块**（§1.3(d)）⇒ 四格全中 ⇒ `pass=3 fail=0`。
`COLUMN_FLOOR_ARMLOG` 的 `bad= tline` 同理：`tline` 臂日志本波被**重取**过（冻结构现声明 `sha16=e061054f73c9a2e7`），冻前块里还是旧值。

**另一条背景对照（非基线，仅留痕）**：`$HOME/w46h/06-verify-all-pre.log`（21:25）是**更早**的一趟，2 红 = `ManagedLayer.Tests` ＋ `COLUMN-FLOOR`；那次 `ManagedLayer.Tests` 的红是"桥的 app-local 副本未同步"（主控在 21:29 手工同步两份副本后单跑 `PASS 1/1`，见 `$HOME/w46h/08-managedlayer-gate-after-sync.log`）⇒ pre2 起该步已绿，**与本次冻结无关**，两趟冻后也都是 `✅ 76/0`。

---

## 4. 异常 / 与任务书预期的偏差（逐条点名）

### 4-A ⚠️ 任务书"标记 2"的**位置**写错了：它不在 `w46-record.txt` 里
任务书说："`/home/links-dev/w21-verify/w46-record.txt` 里 `# RE-FROZEN #46` 出现（工具会把 `{GEN}` 填成 `#46` 并写盘）"。
**实测不成立**：
```
grep -c 'RE-FROZEN #46'    /home/links-dev/w21-verify/w46-record.txt  →  0
grep -c 'RE-FROZEN {GEN}'  /home/links-dev/w21-verify/w46-record.txt  →  1
```
`{GEN}` 的填充发生在 `w27-freeze.py` **写 `ACCEPTANCE-BASELINE.md`** 的那一步（`w27-freeze.py:459` 的 `fill()` ＋ `:472` 的 `out` 拼装），**记录文件本身保持 `{GEN}` 占位不被回写** ⇒ 标记 2 **永远为 0**。
真正的 `# RE-FROZEN #46` 落点是 **`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md:6`**。
⇒ **别把 `w46-record.txt` 当标记**（会白等到 45 min 超时）；下一波请把标记 2 改成 `grep -c '^# RE-FROZEN #46' samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`。

### 4-B ⚠️ "`ARM-LOG-SHA` 同理（从红转绿）"不成立 —— 冻前它就是绿的
冻前 pre2 原文：`ARMLOG_SHA=PASS shape=flat … required=5 declared=5 pass=5 fail=0 noinfo=0`（该步 `✅`）。
更早的 21:25 那趟 pre.log 同样 `ARM-LOG-SHA ✅` / `ARMLOG_SHA=PASS`。
真正"红 → 绿"的是 **`COLUMN-FLOOR` 步内部的那条子读数** `COLUMN_FLOOR_ARMLOG=`（`FAIL n_ok=4 bad= tline` → `PASS n_ok=5 bad=无`）。
⇒ 任务书把**步骤级** `ARM-LOG-SHA` 与 **`COLUMN-FLOOR` 步内的 `COLUMN_FLOOR_ARMLOG`** 混为一谈了。两者名字像，**不是同一颗牙**（前者 `arm-log-sha-check.sh` 只查臂日志形态与前缀集合；后者在 `column-floor-check.sh` 里额外比对**冻结块逐臂 `# ARM-LOG-SHA` 声明值**）。

### 4-C 两趟之间**唯一的数值差**（两趟都 PASS，但如实报）
`diff post-freeze-1.log post-freeze-2.log` = **14 行 / 5 个 hunk**，全部无害：
1. 日志头"根目录 … 21:52:20 / 22:07:45"（时间戳）
2. `TLINE_GATE … outdir=…-215414 / …-220935`（临时目录名）
3. `COLUMN_FLOOR_SELFREPORT … outdir=/tmp/column-floor.RfuI8r / .wJgfW4`（临时目录名；`gate=747c078dbf040862` **两趟相同**）
4. **`FRAMEPRESENCE=PASS frames=80 max_colors=3961 magenta_frames=39 / 40 min_colors=200`** —— 仅 `magenta_frames` 差 1
5. **`THIRDPARTY=PASS frames=42 / 41 max_colors=1642 min_colors=800`** —— 仅帧计数差 1（`max_colors`/`min_colors` 两趟相同）

⇒ 第 4/5 两条是**抓帧循环的时序抖动**（两趟都是 `PASS`，且判据量 `frames`/`max_colors`/`min_colors` 完全一致），**不读成回归**；但"两趟必须逐字相同"这个更强的口径**在这两步上不成立**，下一波若要立"两趟逐字相同"的牙需先给这两步定容差。

### 4-D ⚠️ 我自己踩了一次 `pgrep -f` 自匹配（已修，留痕）
第一版预检用 `pgrep -fc 'run-wpftextdemo.sh'` / `pgrep -fc 'verify-all.sh'`。因为我**用 heredoc 在命令行里内联了整份脚本正文**，我自己的 `bash -c` 命令行的 **cmdline 里就含这两个字面量** ⇒ `appgate=5 verifyall=2` **恒不为 0**，预检会永远等不到 `PRECHECK-OK`（20 min 后 `PRECHECK-FAIL`）。
修法：改用**直接扫 `/proc/*/cmdline`** 并**排除自身 `$$` 与父 `$PPID`**（并把脚本用文件写入、用不含字面量的短命令行启动）⇒ 现场立刻恢复 `verifyall=0`（见 §2.4 的两段日志对比：修前 `appgate=5 verifyall=2`，修后 `appgate=1 verifyall=0`）。
这与本仓纪律 55（`grep` 的 `--` 陷阱）同族：**`pgrep -f` 的判据若由"内联脚本"驱动，判据会把自己算进去**。

### 4-E 收工现场干净
`pgrep -c -x dotnet = 0`、`loadavg 0.54`。中途出现的两个 MSBuild `/nodeReuse:true` 节点进程在收工时也已退场。
**未 `pkill`**；仅按**精确 PID** 停掉了我**自己**的两个进程（内联启动的 `bash -c` 1686128 与它派生的 runner 1686131），因为它们的 cmdline 污染了 4-D 的预检判据。

### 4-F `.xwd` 清理
`find $HOME/w46k -name '*.xwd'` ⇒ **0 个**（`verify-all` 的抓帧产物落在 `/home/links-dev/wfp-runs/**` 与 `/home/links-dev/w34-framepresence-*`/`w37-tpm-*`，**不在** `$HOME/w46k`）。本目录只有 `.log`/`.rc`/`.real`/`.sh`，**无需删除**。

---

## 5. `NOINFO`（缺项登记，不许计入通过）

1. `NOINFO reason=runner-min-MemAvailable-unmeasured` —— 我只在**每趟预检点**与**收工点**采了 `MemAvailable`（2812 / 2819 / 3067 / 2975 / 2980 / 3115 MB，收工 2989 MB），**没有做运行期连续采样** ⇒ 两趟的**运行期最小值**取不到。
2. `NOINFO reason=verifyall-self-declared` —— `VERIFYALL_SELF=… dynamic_trace=NOINFO …`：这是**该步自报**的缺项（非我的仪器缺项），原样转报。
3. `NOINFO reason=magenta-frames-variance-cause-unlocated` —— §4-C 第 4/5 条的**成因**（是抓帧时序、还是被拍窗口的动画/闪烁）**未定位**；我只证明两趟判据量相同且都 PASS，**没有**证明"差 1 不影响任何结论"以外的更多。
4. `NOINFO reason=freeze-marker-2-as-specified-never-fires` —— 见 §4-A：任务书给的标记 2 判据**在本仓工具链下恒为 0**（不是"这次没出现"，是**判据写错了位置**）。

---

## 6. 复算用的命令清单（只读）

```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
# 冻结标记
grep -n 'BASELINE-FROZEN gen=#46' "$R/docs/CURRENT-STATE.md"
(cd "$R" && bash build/MilBridge/tools/baseline-sha-check.sh)
grep -n '^# RE-FROZEN #46' "$R/samples/WpfTextDemo/ACCEPTANCE-BASELINE.md"
sed -n '56,63p' "$R/samples/WpfTextDemo/ACCEPTANCE-BASELINE.md"
# 两趟读数
grep -n 'COLUMN_FLOOR\|ARMLOG_SHA\|BASELINEGEN\|VERIFYALL_SELF\|步骤通过\|用例通过\|结论：' \
  /home/links-dev/w46k/post-freeze-1.log /home/links-dev/w46k/post-freeze-2.log
# 两趟逐行对账
diff /home/links-dev/w46k/post-freeze-1.log /home/links-dev/w46k/post-freeze-2.log
# 冻前对照
grep -n 'COLUMN_FLOOR\|ARMLOG_SHA\|BASELINEGEN\|步骤通过\|结论：' \
  /home/links-dev/w46h/06-verify-all-pre2.log
```

## 7. 产物清单

| 文件 | sha16 | 说明 |
|---|---|---|
| `build/MilBridge/W46K-report.md` | 本文件（**自指哈希无法内嵌**；sha16 由本趟最终回复给出） | 本报告 |
| `$HOME/w46k/post-freeze-1.log` | `9832c2b753c6917b` | 冻后第 1 趟全文 |
| `$HOME/w46k/post-freeze-2.log` | `1c878b1b9e898676` | 冻后第 2 趟全文 |
| `$HOME/w46k/post-freeze-{1,2}.rc` / `.real` | — | `0` / `848`、`0` / `851` |
| `$HOME/w46k/freeze-marker.log` | — | 冻结等待器逐轮读数 |
| `$HOME/w46k/precheck.log` | — | 两趟开工预检读数 |
| `$HOME/w46k/wait-freeze.sh`、`run-post-freeze.sh`、`extract.sh` | — | 等待器 / 跑批器 / 抽取器 |
| `$HOME/w46h/06-verify-all-pre2.log` | `d17c114b20345183` | **冻前权威对照**（主控的，只读引用） |

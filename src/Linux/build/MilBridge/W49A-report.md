# W49A 报告 —— 波 `#47` 冻后 `verify-all` 两趟

- 车道 `lane=W49A`｜主机 `linksdev-VirtualBox`｜kernel `6.8.0-138-generic`｜`nproc=3`
- 开工 `2026-09-19 23:33:54`｜收工 `2026-09-20 00:12:35`（+08:00）
- 仓根 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`
- **本车道只跑 `verify-all.sh` 两趟 + 只读取证**；未构建任何产品件、未改任何仓内文件（只新增本报告）。

---

## 0 一行结论

**第一趟（`23:34:09`→`23:48:49`）`rc=0`、`25 ✅ / 0 ❌`、`871 通过 / 2 跳过`，与冻前那趟唯一红 `COLUMN-FLOOR` 的转绿对得上 ⇒ 这一趟是有效读数。**
**第二趟（`23:48:55`→`00:09:01`）`rc=1`，且这一趟不可归因** —— 它同时踩了**两条独立的并发事故**：

1. **`[0]` 复用了别人的临时 X 显示 `:66`（不是第一趟的 `:97`）**，该显示在步 `[2]` 之前就已经连不上 ⇒ `X11Probe.XOpenDisplay` 返回 NULL ⇒ **47 例依赖 X 的用例静默变跳过**（`SKIP_GUARD=FAIL`，这颗牙**正确地**抓到了）＋ 一条**非 X 守卫**的端到端用例硬红（`ManagedLayer.Tests rc=1`）。
2. **另一条车道在我第二趟执行期间改写了 `verify-all.sh`**（`gen=#47` → `gen=#48`，`sha16 bde0bce61f2ffbac` → `50e8fb979a979921`，mtime `23:53:14`）⇒ bash 边读边执行脚本 ⇒ **步 `[6] FrameProbe-frame` 被执行两次**、`verify-all.sh: 行 517: … 未找到命令` 三条 stderr。

⇒ **`#47` 的"冻后两趟"目前只有一趟有效；第二趟必须在并发静默、且 `verify-all.sh`/树定格之后原样重取。**

我不修改任何东西（按任务书：`rc≠0` ⇒ 报读数并停）。

---

## 1 两趟读数表

| 项 | 第一趟 | 第二趟 |
|---|---|---|
| 命令 | `bash verify-all.sh > $HOME/w49a/post-freeze-1.log 2>&1` | `bash verify-all.sh > $HOME/w49a/post-freeze-2.log 2>&1` |
| 起 / 止 | `2026-09-19 23:34:09` / `23:48:49` | `2026-09-19 23:48:55` / `2026-09-20 00:09:01` |
| **rc** | **0** | **1** |
| `real`（实测） | **880 s**（≈14.7 min） | **1206 s**（≈20.1 min） |
| 步骤通过 / 失败 | **25 / 0** | 25 / 1（**但见 §4.3：这个 25 是虚高的**） |
| 失败步名 | **（空）** | `ManagedLayer.Tests` ＋ `SKIP-GUARD` |
| 用例通过 / 跳过 | **871 / 2** | 769 / 23 |
| `SKIP_GUARD` | `PASS … total_skipped=2 violations=none` | **`FAIL` … `total_skipped=23` `reason=x-required-but-skipped`** |
| 结论行 | `结论：✅ 全部通过` | `结论：❌ 失败项：ManagedLayer.Tests SKIP-GUARD` |
| 日志 | `$HOME/w49a/post-freeze-1.log`（9,334 B，sha16 **`eba8fb22d1d8dda8`**） | `$HOME/w49a/post-freeze-2.log`（13,466 B，sha16 **`a7139fdc6d87fb0d`**） |
| 起时 `loadavg` / `MemAvailable` | `0.64 1.03 1.43` / `2,630,056 kB` | `1.74 2.20 1.87` / `2,385,620 kB` |
| 止时 `loadavg` / `MemAvailable` | `1.89 2.24 1.89` / `2,126,220 kB` | `0.68 1.08 1.48` / `2,454,044 kB` |
| 选中的 X 显示 | **`:97`** | **`:66`** ← ⚠️ 见 §4.1 |

前置检查（两趟之前，本车道现场核）：`docs/CURRENT-STATE.md:9` = `> BASELINE-FROZEN gen=#47 sha16=9b9e3cb7bcb8280b file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`；
现场 `sha256sum samples/WpfTextDemo/ACCEPTANCE-BASELINE.md | cut -c1-16` = `9b9e3cb7bcb8280b`（553,550 B，mtime `2026-09-19 23:33:41`）；`grep -m1 -o '^# RE-FROZEN #[0-9A-Za-z]*'` = `# RE-FROZEN #47` ⇒ 声明与现场一致。
**跑之前 `pgrep -a dotnet` 为空**（无别人的构建在飞）；`Xvfb :97`（PID 68922，`Fri Sep 18 23:13:36` 起）在跑。

---

## 2 关键原文（逐字，两趟）

### 2.1 第一趟（`post-freeze-1.log`）

```
48:      · 自报口径 BASELINESHA=PASS live=9b9e3cb7bcb8280b decl=9b9e3cb7bcb8280b
49:      · 自报口径 BASELINEGEN=PASS decl_gen=#47 file_newest_gen=#47
54:      · 自报口径 ARMLOG_SHA=PASS shape=flat logdir=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux/build/MilBridge/arm-logs required=5 declared=5 pass=5 fail=0 noinfo=0
66:      · 自报口径 VERIFYALL_SELF=PASS names=25 decl=25 gen=#47 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO vfile_sha16=bde0bce61f2ffbac
82:      · 自报口径 COLUMN_FLOOR_ARMLOG=PASS n_decl=5 n_ok=5 bad=无
84:      · 自报口径 COLUMN_FLOOR=PASS reason=decl==frozen-and-decl>=corpus pass=3 fail=0 noinfo=0 selfreport=PASS reg=00a75a87ec5ed0d6 base=9b9e3cb7bcb8280b corpus=0cebc0afd5142fbf
108: SKIP_GUARD=PASS x_state=available x_suite_skipped=0 x_suite_units=0 x_suite_corpus_max=0 total_skipped=2 violations=none reason=none
105: 步骤通过 25  ❌ 失败 0
106: 用例通过 871  跳过 2
109: 结论：✅ 全部通过
```

`[14]` 三条子档也全绿（同趟原文）：

```
      · 自报口径 COLUMN_FLOOR_OVERFLOWED_JUDGED_MIN=PASS arm=tab-oracle-anchor col=OVERFLOWED key=judged_min decl=421 frozen=421 corpus_min=421
      · 自报口径 COLUMN_FLOOR_START_JUDGED_MIN=PASS arm=tab-oracle-anchor col=START key=judged_min decl=615 frozen=615 corpus_min=615
      · 自报口径 COLUMN_FLOOR_START_RELEASED_MIN=PASS arm=tab-oracle-anchor col=START key=released_min decl=194 frozen=194 corpus_min=194
      · 自报口径 COLUMN_FLOOR_CORPUS=PASS file=…/tab-anchor-oracle.json live=0cebc0afd5142fbf decl=0cebc0afd5142fbf
      · 自报口径 COLUMN_FLOOR_SELFREPORT=PASS gate=747c078dbf040862 outdir=/tmp/column-floor.AohuWB
```

`[0]` 与 `[6]`（第一趟）：

```
  ✅ 复用已运行的 Xvfb（实测 display :97，注意不是 :99）
  DISPLAY=:97（已用 xdpyinfo 验证可连）
  X_STATE=available（判据：xdpyinfo 对 DISPLAY=:97 成功 ⇒ available）
[6] 帧列（FrameProbe：帧原点机制；断 帧红==0，不判结构族）
  FrameProbe-frame             ✅
```

### 2.2 第二趟（`post-freeze-2.log`）

```
 7:  ✅ 复用已运行的 Xvfb（实测 display :66，注意不是 :99）
 8:  DISPLAY=:66（已用 xdpyinfo 验证可连）
 9:  X_STATE=available（判据：xdpyinfo 对 DISPLAY=:66 成功 ⇒ available）
32:  ManagedLayer.Tests           ❌  (rc=1)
75:      · 自报口径 BASELINESHA=PASS live=9b9e3cb7bcb8280b decl=9b9e3cb7bcb8280b
76:      · 自报口径 BASELINEGEN=PASS decl_gen=#47 file_newest_gen=#47
81:      · 自报口径 ARMLOG_SHA=PASS shape=flat logdir=… required=5 declared=5 pass=5 fail=0 noinfo=0
89:      · 自报口径 DEFREG=PASS declared=94 route_ids=94（每个声明编号在其 req 的每个 route 文件里都在；无未声明编号）
93:      · 自报口径 VERIFYALL_SELF=PASS names=25 decl=25 gen=#48 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO vfile_sha16=50e8fb979a979921
109:      · 自报口径 COLUMN_FLOOR_ARMLOG=PASS n_decl=5 n_ok=5 bad=无
111:      · 自报口径 COLUMN_FLOOR=PASS reason=decl==frozen-and-decl>=corpus pass=3 fail=0 noinfo=0 selfreport=PASS reg=00a75a87ec5ed0d6 base=9b9e3cb7bcb8280b corpus=0cebc0afd5142fbf
132: 步骤通过 25  ❌ 失败 1
133: 用例通过 769  跳过 23
136: SKIP_GUARD=FAIL x_state=available x_suite_skipped=21 x_suite_units=3 x_suite_corpus_max=0 total_skipped=23 violations= HelloMil.Tests(跳过 1 > 上限 0：X 可用却被跳过) Presentation.Tests(跳过 7 > 上限 0：X 可用却被跳过) Windowing.Tests(跳过 13 > 上限 0：X 可用却被跳过) reason=x-required-but-skipped
137: 结论：❌ 失败项：ManagedLayer.Tests SKIP-GUARD
138: 射程：❌ 跳过**越过声明上限**（静默关牙；reason=x-required-but-skipped ）： HelloMil.Tests(跳过 1 > 上限 0：X 可用却被跳过) Presentation.Tests(跳过 7 > 上限 0：X 可用却被跳过) Windowing.Tests(跳过 13 > 上限 0：X 可用却被跳过)
```

第二趟 `[2]` 各套件（逐字）：

```
  Windowing.Tests              ✅  通过 26   跳过 13  合计 39
  HelloMil.Tests               ✅  通过 18   跳过 1   合计 19
  ManagedLayer.Tests           ❌  (rc=1)
  Presentation.Tests           ✅  通过 1    跳过 7   合计 8
```

失败步日志尾部 40 行（`/tmp/verify-all-ManagedLayer_Tests_.log`，**550 B，mtime `2026-09-19 23:49`，全文只有 5 行**，即该步日志的末 40 行 = 全文）：

```
/home/links-dev/netTest/wpf-linux-20260906/wpf-linux/tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/bin/Release/net10.0/WpfGfx.Linux.ManagedLayer.Tests.dll (.NETCoreApp,Version=v10.0)的测试运行
总共 1 个测试文件与指定模式相匹配。
[xUnit.net 00:00:00.36]     WpfGfx.Linux.Tests.ManagedLayer.M7cInputPathTests.端到端_真应用收到指针与按键_不崩且事件到达窗口 [FAIL]

失败!  - 失败:     1，通过:    49，已跳过:    26，总计:    76，持续时间: 544 ms - WpfGfx.Linux.ManagedLayer.Tests.dll (net10.0)
```

第二趟 stderr 的 shell 异常（逐字，`post-freeze-2.log:64-66`）：

```
verify-all.sh: 行 517: 帧红=0: 未找到命令
verify-all.sh: 行 517: 判定行=421: 未找到命令
verify-all.sh: 行 517: /: 是一个目录
```

---

## 3 与冻前那趟的对照

冻前那趟 = `$HOME/w48a/06-verify-all-pre.log`（**8,664 B**；**现场复算** `sha256sum … | cut -c1-16` = **`a09909bb3a76224f`**，与 `docs/WAVE47-PREREGISTRATION.md:59` 的自报值一致）。

| 项 | 冻前 `w48a/06` | 冻后第一趟 | 冻后第二趟（无效） |
|---|---|---|---|
| 步骤通过 / 失败 | 24 / 1 | **25 / 0** | 25 / 1（虚高，见 §4.3） |
| 唯一/追加失败步 | `COLUMN-FLOOR` | （无） | `ManagedLayer.Tests` ＋ `SKIP-GUARD` |
| `COLUMN_FLOOR_ARMLOG` | `FAIL n_decl=5 n_ok=4 bad= tline` | **`PASS n_decl=5 n_ok=5 bad=无`** | `PASS … bad=无` |
| `COLUMN_FLOOR` | `FAIL reason=floor-lowered-… fail=1 … base=dd31a7701fc77829` | **`PASS … fail=0 … base=9b9e3cb7bcb8280b`** | `PASS … base=9b9e3cb7bcb8280b` |
| `BASELINESHA` | `PASS live=dd31a7701fc77829` | `PASS live=9b9e3cb7bcb8280b` | 同第一趟 |
| `ARMLOG_SHA` | `PASS` | `PASS` | `PASS` |

**结论（三条，与 `docs/WAVE46-CLOSEOUT-RUNBOOK.md` §12 的现场纠正一致）：**

1. **冻前红 → 冻后绿的是 `COLUMN_FLOOR_ARMLOG` 这一颗**（`bad= tline` → `bad=无`），总判 `COLUMN_FLOOR` 随之转绿；**不是** `ARM-LOG-SHA`（它冻前就已经 `PASS`）。
2. 冻前那份日志里 `BASELINESHA`/`BASELINEGEN` **本来就是 `PASS`**（`live=decl=dd31a7701fc77829`、`decl_gen=#46`）—— `docs/WAVE47-PREREGISTRATION.md:57` 的措辞"**冻前 BASELINE-SHA/ARM-LOG-SHA/COLUMN-FLOOR(ARMLOG) 红 ⇒ 冻后同批绿**"**与盘上日志不符**（`a09909bb3a76224f` 里 `BASELINESHA=PASS`、`ARMLOG_SHA=PASS` 各 1 次命中，`COLUMN_FLOOR*=FAIL` 2 次命中）。如实记，不改判据。
3. 冻后 `base=` 从 `dd31a7701fc77829` 换成 `9b9e3cb7bcb8280b`、`reg=` 两趟都是 `00a75a87ec5ed0d6`（= 重钉后的登记表，与 `docs/WAVE47-PREREGISTRATION.md:60` 的 `1fa4c4540fe1b69f(402) → 00a75a87ec5ed0d6(406)` 对得上）。

---

## 4 异常（第二趟为什么不可归因）

### 4.1 异常①：`[0]` 劫持了别人的**临时** X 显示 `:66`，它在步 `[2]` 之前就没了

**机制（源码级）**：`verify-all.sh:366-373` 的分支逻辑是"`:99` 连不上 ⇒ 遍历 `pgrep -a Xvfb` 抽出的显示号，**取第一个 `xdpyinfo` 通的**"：

```bash
    for d in $(pgrep -a Xvfb 2>/dev/null | grep -oE ' :[0-9]+' | tr -d ' :' | sort -u); do
      if DISPLAY=:$d xdpyinfo > /dev/null 2>&1; then chosen=":$d"; break; fi
    done
```

⇒ ① `sort -u` 是**字符串序**，`66` < `97` ⇒ 谁在 `:97` 之外还活着一个 Xvfb，谁就被优先选中；② 选中后**只验证一次**（`[0]` 那一刻），之后整趟**不再复核**；③ 它选中的可能是**另一条车道的私有显示**——那条车道随时会把它收掉。

**取证（逐条）**：

- 第一趟选 `:97`、第二趟选 `:66`（日志原文见 §2）。
- 现在 `ls -la /tmp/.X11-unix/` 只有 **`X0 X1 X10 X97`**（**没有 `X66`**）；`ps -eo pid,lstart,cmd | grep -iE 'xvfb|xorg'` 只有 `Xvfb :97`（PID 68922，`Fri Sep 18 23:13:36`）、`Xwayland :0`、`Xorg :10` ⇒ **`:66` 的 server 已经不存在**，且它的 socket 也没留下（干净退出）。
- **`:66` 在 23:34 时还不存在**：我开工那次 `pgrep -a Xvfb | head` 只回 `68922 Xvfb :97 …` 一行 ⇒ `:66` 是 `23:34`–`23:48` 之间由**别的车道**起、又在其后收掉的。
- **`:66` 在步 `[2]` 时已经连不上（证明）**：`ManagedLayer.Tests` 该趟 `已跳过: 26`，而 `X11Fact`/`X11FactAttribute` 的跳过条件是**发现期** `!X11Probe.Available`，即 `XOpenDisplay(null)` 返回 NULL（`tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/X11Guard.cs:44` `ProbeCore()` / `:51` `XOpenDisplay(null)` / `:53` `返回 NULL（server 没在听）`）；同一时刻 `Windowing.Tests` 跳 13、`Presentation.Tests` 跳 7、`HelloMil.Tests` 跳 1，合计 **47**（26+13+7+1）。
- **端到端那条硬红同源（证据链）**：`M7cInputPathTests.端到端_真应用收到指针与按键_不崩且事件到达窗口`（`M7cInputPathTests.cs:371`）是**普通 `[Fact]`（不是 `[X11Fact]`）**，只在 `DISPLAY` **未设置**时才跳过（`:401-406`）；第二趟 `DISPLAY=:66` 已设 ⇒ 它**照跑**，把 `DISPLAY=:66` 塞给子进程 `run-hellowpf.sh`。而该 runner 在**第 69-73 行**先验 X：
  ```bash
  if ! command -v xdpyinfo >/dev/null 2>&1 || ! xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
      echo "❌ DISPLAY=$DISPLAY 上没有 X server（…）" >&2
      …
      exit 2
  fi
  ```
  而它的运行目录 `OUT="${M7C_RUN_DIR:-/tmp/m7c-hellowpf-$$}"` **要到第 157 行**才 `rm -rf "$OUT"; mkdir -p "$OUT"`。
  **读数**：`ls -dla /tmp/m7c-hellowpf-*` 最新一个是 **`/tmp/m7c-hellowpf-1881204`，mtime `2026-09-19 23:35:13`（= 第一趟那次，正对照：跑成功的趟**会**留目录）**，**第二趟（`23:49`）没有留下任何 `m7c-hellowpf-*` 目录** ⇒ runner **在创建运行目录之前就退出了**；结合"同一进程组内 `XOpenDisplay` 已返回 NULL"与"该脚本只有 `:38` 用法、`:64` grep 自检、`:69` X 检查三个早退点，而后两者与两趟差异无关" ⇒ **它在 `:69` 的 X 检查上 `exit 2`**。
  ⇒ 用例在 `00:00:00.36` 就 `[FAIL]`，与"runner 立刻退出、判据行 `INPUT_PROBE=` 从未出现"完全一致（`M7cInputPathTests.cs:424` 的 `Assert.True(marker != null, …)`）。

**判定**：第二趟的 `ManagedLayer.Tests rc=1` 与 `SKIP-GUARD=FAIL` **是环境假红，不是产品回归**（第一趟同一件、同一套件 `通过 76 跳过 0`）。
⚠️ 诚实边界：`dotnet test -v q` **不打印失败断言文本**，所以"具体是哪一条 `Assert` 失败"= **NOINFO**；上面这条链是"目录缺失 + 跳过语义 + 脚本早退点"三条独立读数合成的，属**强推断**，不是逐字直读。
⚠️ 顺带点名一颗真牙：`SKIP-GUARD`（`verify-all.sh:181-201` 的上限表 + 末尾断言）**在这趟正确地红了** —— 它把"47 例 X 用例静默变跳过"从"绿得看不见"变成硬红。这条牙值得保留。

### 4.2 异常②：**树在执行中被改**（`verify-all.sh` `#47` → `#48`）

**取证（三条，互相独立）**：

1. **同一趟日志内部自相矛盾**：第二趟 `:76` 报 `BASELINEGEN=PASS decl_gen=#47`，而 `:93` 报 `VERIFYALL_SELF=PASS … gen=#48 … vfile_sha16=50e8fb979a979921`；第一趟同位置（`:49` / `:66`）是 `decl_gen=#47` / `gen=#47 … vfile_sha16=bde0bce61f2ffbac`。
2. **现场件**：`verify-all.sh` 现为 **79,234 B，mtime `2026-09-19 23:53:14`，sha16 `50e8fb979a979921`**；而**冻结块** `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md:36` 与 `:42` 逐字声明 `#47` 那一代的 `verify-all.sh` sha16 = **`bde0bce61f2ffbac`**。mtime `23:53:14` 落在**第二趟执行区间内**（`23:48:55`–`00:09:01`）。
3. **文件内容**：现树 `verify-all.sh:44-45` **同时存在两行声明**（`#48` 插在 `#47` 之上）：
   ```
   44:# VERIFYALL-STEPS-DECL: 25 gen=#48   ← `#48` **不动步数**（修 `D-G56`…另修 `D-G57`——只动 `windowsbase`/`pf` 两位）
   45:# VERIFYALL-STEPS-DECL: 25 gen=#47   ← `#47` **不动步数**（修 `D-G55`…）
   ```
   另有 `DEFREG` 从第一趟的 `declared=93 route_ids=93` 变成第二趟的 `declared=94 route_ids=94`（`:89`）⇒ 同期还有**别的判定输入**在动。

**旁证（时间线）**：`docs/WAVE48-PREREGISTRATION.md` mtime `2026-09-19 23:36:37`（**第一趟开工后 2.5 min** 就开了 `#48` 波），`verify-all.sh` mtime `23:53:14` 落在**第二趟执行中**。
**未受影响**：`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（`9b9e3cb7bcb8280b`，mtime `23:33:41`）与 `build/MilBridge/known-red.json`（`00a75a87ec5ed0d6`，mtime `23:11:54`）两趟之间**逐位未变** ⇒ 第二趟的 `BASELINE-SHA`/`COLUMN-FLOOR` 两项绿是**真的**，但它们不构成"第二趟有效"。
**`inputs_fp` 面**：`build/close-wave.sh` 的 `fp_inputs()` 函数体里**没有** `verify-all.sh` 这个路径（现场 `sed -n '/^fp_inputs()/,/^}/p' | grep -n 'verify-all'` 只命中注释行）⇒ 这次改写**不直接**牵动 `inputs_fp`；但**被改的正是"验证器本身"**，所以第二趟的 `VERIFYALL_SELF` 是对**另一代脚本**的自洽检查。

### 4.3 异常③：步数自洽被破坏 —— 步 `[6]` 被执行了**两次**

- 机械读数：`grep -ac '^\[6\] 帧列' post-freeze-2.log` = **2**；按步名计 `FrameProbe-frame` 出现 **2 次**（第一趟各 1 次）。对应原文里 `[6]` 整块（标题 + `FRAME_STEP=` + `FRAME_STEP_LEGS=`）**逐字出现两遍**（`:57-63` 与 `:68-71`）。
- 这正是 **bash 增量读取脚本 + 脚本被就地改写**的指纹；同一现象的另一半是 `:64-66` 的 `verify-all.sh: 行 517: 帧红=0: 未找到命令` / `判定行=421: 未找到命令` / `/: 是一个目录`（bash 落在新内容的半行上）。
- **后果（重要）**：第二趟的 `步骤通过 25` **不是 25 个唯一步骤通过** —— 声明 25 步里实际是 **24 步通过 + 1 步失败（`ManagedLayer.Tests`）**，多出来的那 1 来自 `[6]` 被计了两次。⇒ **第二趟的"步数/步名"这一栏本身就不可当读数用**，这也解释了 §1 表里"25 通过 + 1 失败 = 26 > 25"的算术矛盾。

### 4.4 收工时的在飞状态（**我停手之后**才起来的，但主控重取第二趟前必须知道）

第二趟于 `00:09:01` 结束；`00:11:54`（+2 min 53 s）**另一条车道 `W50A` 起了整波重建**：

```
1943007     884 Sun Sep 20 00:11:54 2026   bash -c cd …/wpf-linux && … && WAVE_OWNER=w50a bash build/integration-wave.sh > $HOME/w50a/02-integration-wave.log 2>&1 …
1943012 1943007 Sun Sep 20 00:11:54 2026   bash build/integration-wave.sh
1944086 1944085 Sun Sep 20 00:13:06 2026   dotnet build build/PresentationFramework.Linux/PresentationFramework.Linux.csproj -c Release -m:1 --nologo -v q
```

⇒ **现树正在被重建**（`PresentationFramework` 正在编），`verify-all.sh` 已被改到 `#48`。**第二趟的重取必须等这条整波静默**（`pgrep -a dotnet` 空、且 `verify-all.sh` / `known-red.json` / 基线件 mtime 稳定 ≥25 s），否则重复本报告 §4.2 的事故。
本车道**未**介入、未停别人的进程（按纪律只用 `ps` 读、不 `pkill`）。

---

## 5 `NOINFO`（如实标，不许当绿）

1. `ManagedLayer.Tests` 那条失败用例的**断言原文**：`-v q` 不打印 ⇒ **NOINFO**（`/tmp/verify-all-ManagedLayer_Tests_.log` 全文 5 行，无栈无消息）。**未**用重跑去补（任务书要求 `rc≠0` 时停；且现树已不是冻结树）。
2. `:66` 那条 server 的**归属车道与退出方式**：socket 与进程都已消失 ⇒ **NOINFO**（只能证明"`23:34` 不存在 / `[0]` 时可连 / 步 `[2]` 时不可用 / 现在不存在"）。
3. `verify-all.sh` 被改的**次数与每次的时刻**：mtime 只留最后一次（`23:53:14`）⇒ **NOINFO**（可证明的只有"第二趟 `:93` 读到的是 `50e8fb979a979921` = 现树"）。
4. **第二趟是否还有其他被改写牵连的读数**：`DEFREG 93→94` 说明别的输入也在动，本车道只读了与本次两趟有关的几件 ⇒ 其余 **NOINFO**。
5. `.xwd` 清理：`$HOME/w49a/` 下 **0 个 `.xwd`**（现场 `find $HOME/w49a -name '*.xwd'` 空）⇒ 本车道**无需删除**。附带读数：`23:30` 之后被创建/改动的 `.xwd` 共 **189 个、约 221 MB**，全在**各步骤自己的目录**里（如 `$HOME/w34-framepresence-232958/`、`$HOME/w48d-run/`），**不在本车道写域内，未删**。

---

## 6 复算命令（谁都能重放）

```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux; cd "$R"
sha256sum $HOME/w49a/post-freeze-1.log | cut -c1-16     # eba8fb22d1d8dda8
sha256sum $HOME/w49a/post-freeze-2.log | cut -c1-16     # a7139fdc6d87fb0d
grep -aE '步骤通过|用例通过|结论：' $HOME/w49a/post-freeze-1.log   # 25 / 0 、871 / 2 、✅
grep -aE '步骤通过|用例通过|结论：' $HOME/w49a/post-freeze-2.log   # 25 / 1 、769 / 23 、❌ ManagedLayer.Tests SKIP-GUARD
grep -aoE '(BASELINESHA|BASELINEGEN|ARMLOG_SHA|COLUMN_FLOOR_ARMLOG|COLUMN_FLOOR|VERIFYALL_SELF)=[A-Z]+' \
  $HOME/w49a/post-freeze-1.log | sort | uniq -c        # 六项全 PASS
grep -ac '^\[6\] 帧列' $HOME/w49a/post-freeze-2.log      # 2（第一趟 = 1）—— 步 [6] 被执行两次
sha256sum verify-all.sh | cut -c1-16; stat -c '%y' verify-all.sh   # 50e8fb979a979921 ; 2026-09-19 23:53:14
ls -dla --time-style='+%F %T' /tmp/m7c-hellowpf-* | tail -3        # 最新 23:35:13（第二趟 23:49 无目录）
ls -la /tmp/.X11-unix/                                             # 无 X66
sha256sum $HOME/w48a/06-verify-all-pre.log | cut -c1-16            # a09909bb3a76224f（冻前那趟）
```

---

## 7 给主控的三条处置建议（**建议，不是我的动作**）

1. **第二趟原样重取**：等 `#48`/`w50a` 这波整波重建静默（`pgrep -a dotnet` 空、`verify-all.sh` 与判定输入 mtime 稳定 ≥25 s，见 §4.4）后，从 `$HOME/w49a/` 另起一份日志重跑一趟。判据仍是 `rc=0` ∧ `步骤通过 25 ❌ 失败 0` ∧ 失败步名为空 ∧ `SKIP_GUARD=PASS`（`total_skipped=2`，即只跳 `Rendering.Tests` 的静态 2 例）。
2. **X 显示这条洞值得当缺陷登记**（`verify-all.sh:366-373`）：现在的"复用"会**优先挑字符串序最小的**（`:66` < `:97`），并且**不区分"本仓长期 Xvfb"与"别人的临时私有显示"**，选定后**整趟不再复核**。最小加固方向（**未做，仅建议**）：① 只认"本仓约定显示"（`start-xvfb.sh` 的那一个）或对候选加**排除名单**；② 或在每个用 X 的步之前**复验** `DISPLAY` 可连（`runner` 自己那套 `:69` 检查就是现成判据）。**注意别把它当"第二趟红了"的借口**：这条洞的后果是"**假红**"，与"产品坏了"方向相反。
3. **`#47` 的冻后验证现状**：第一趟有效、第二趟无效 ⇒ 若流程要求"两趟皆绿"，**当前不满足**；是否接受"一趟绿 + 一趟环境无效"由主控裁定，我不替它判。

---

**报告自身读数**：本文件由车道 `W49A` 写于 `2026-09-20 00:12+08:00`；跑完两趟后 `loadavg=2.82 1.41 1.48`、`MemAvailable=2,468,880 kB`；未留下本车道的 `dotnet`/MSBuild 进程（`pgrep -a dotnet` 仅两条 `/nodeReuse:true` 的空闲 MSBuild 节点，属两趟构建复用，非在飞构建）。
